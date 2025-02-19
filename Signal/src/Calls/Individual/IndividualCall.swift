//
//  Copyright (c) 2022 Open Whisper Systems. All rights reserved.
//

import Foundation
import SignalMessaging
import SignalServiceKit
import SignalRingRTC

public enum CallState: String {
    case idle
    case dialing
    case answering
    case remoteRinging

    // The local ringing state is a bit more complex since we sometimes kick off
    // a CallKit ring before RingRTC is ready to answer. We can only answer the call
    // once both the user has answered and RingRTC is ready.
    case localRinging_Anticipatory      // RingRTC not ready. User has not answered
    case localRinging_ReadyToAnswer     // RingRTC ready. User has not answered
    case accepting                      // RingRTC not ready. User has answered

    case connected
    case reconnecting
    case localFailure // terminal
    case localHangup // terminal
    case remoteHangup // terminal
    case remoteHangupNeedPermission // terminal
    case remoteBusy // terminal
    case answeredElsewhere // terminal
    case declinedElsewhere // terminal
    case busyElsewhere // terminal
}

public enum CallAdapterType {
    case `default`, nonCallKit
}

public enum CallDirection {
    case outgoing, incoming
}

public protocol IndividualCallDelegate: AnyObject {
    func individualCallStateDidChange(_ call: IndividualCall, state: CallState)
    func individualCallLocalVideoMuteDidChange(_ call: IndividualCall, isVideoMuted: Bool)
    func individualCallLocalAudioMuteDidChange(_ call: IndividualCall, isAudioMuted: Bool)
    func individualCallHoldDidChange(_ call: IndividualCall, isOnHold: Bool)
    func individualCallRemoteVideoMuteDidChange(_ call: IndividualCall, isVideoMuted: Bool)
    func individualCallRemoteSharingScreenDidChange(_ call: IndividualCall, isRemoteSharingScreen: Bool)
}

/**
 * Data model for a WebRTC backed voice/video call.
 *
 * This class' state should only be accessed on the main queue.
 */
@objc
public class IndividualCall: NSObject, IndividualCallNotificationInfo {

    // Mark -

    var backgroundTask: OWSBackgroundTask? {
        didSet {
            AssertIsOnMainThread()

            Logger.info("")
        }
    }

    var callId: UInt64? {
        didSet {
            AssertIsOnMainThread()

            Logger.info("")
        }
    }

    let callAdapterType: CallAdapterType

    weak var remoteVideoTrack: RTCVideoTrack? {
        didSet {
            AssertIsOnMainThread()

            Logger.info("")
            delegate?.individualCallRemoteVideoMuteDidChange(self, isVideoMuted: !isRemoteVideoEnabled)
        }
    }

    var isRemoteVideoEnabled = false {
        didSet {
            AssertIsOnMainThread()

            Logger.info("\(isRemoteVideoEnabled)")
            delegate?.individualCallRemoteVideoMuteDidChange(self, isVideoMuted: !isRemoteVideoEnabled)
        }
    }

    var isRemoteSharingScreen = false {
        didSet {
            AssertIsOnMainThread()

            Logger.info("\(isRemoteSharingScreen)")
            delegate?.individualCallRemoteSharingScreenDidChange(self, isRemoteSharingScreen: isRemoteSharingScreen)
        }
    }

    var networkRoute: NetworkRoute = NetworkRoute(localAdapterType: .unknown)

    // MARK: -

    // tracking cleanup
    var wasReportedToSystem = false
    var wasRemovedFromSystem = false

    @objc
    public let remoteAddress: SignalServiceAddress

    public var isEnded: Bool {
        switch state {
        case .localFailure, .localHangup, .remoteHangup, .remoteHangupNeedPermission, .remoteBusy, .answeredElsewhere, .declinedElsewhere, .busyElsewhere:
            return true
        case .idle, .dialing, .answering, .remoteRinging, .localRinging_Anticipatory, .localRinging_ReadyToAnswer, .accepting, .connected, .reconnecting:
            return false
        }
    }

    public let direction: CallDirection

    // Distinguishes between calls locally, e.g. in CallKit
    @objc
    public let localId: UUID

    public let thread: TSContactThread

    public let sentAtTimestamp: UInt64

    public var callRecord: TSCall? {
        didSet {
            AssertIsOnMainThread()
            assert(oldValue == nil)

            updateCallRecordType()
        }
    }

    public lazy var hasLocalVideo = offerMediaType == .video {
        didSet {
            AssertIsOnMainThread()

            delegate?.individualCallLocalVideoMuteDidChange(self, isVideoMuted: !hasLocalVideo)
        }
    }

    var deferredAnswerCompletion: (() -> Void)? {
        didSet {
            owsAssertDebug(deferredAnswerCompletion == nil || state == .accepting)
        }
    }

    public var state: CallState {
        didSet {
            AssertIsOnMainThread()
            Logger.debug("state changed: \(oldValue) -> \(self.state) for call: \(self)")

            updateCallRecordType()

            delegate?.individualCallStateDidChange(self, state: state)
        }
    }

    public var offerMediaType: TSRecentCallOfferType = .audio

    // We start out muted if the record permission isn't granted. This should generally
    // only happen for incoming calls, because we proactively ask about it before you
    // can make an outgoing call.
    public var isMuted = AVAudioSession.sharedInstance().recordPermission != .granted {
        didSet {
            AssertIsOnMainThread()

            Logger.debug("muted changed: \(oldValue) -> \(self.isMuted)")

            delegate?.individualCallLocalAudioMuteDidChange(self, isAudioMuted: isMuted)
        }
    }

    public var isOnHold = false {
        didSet {
            AssertIsOnMainThread()
            Logger.debug("isOnHold changed: \(oldValue) -> \(self.isOnHold)")

            delegate?.individualCallHoldDidChange(self, isOnHold: isOnHold)
        }
    }

    public weak var delegate: IndividualCallDelegate?

    // MARK: Initializers and Factory Methods

    init(direction: CallDirection, localId: UUID, state: CallState, thread: TSContactThread, sentAtTimestamp: UInt64, callAdapterType: CallAdapterType) {
        self.direction = direction
        self.localId = localId
        self.state = state
        self.remoteAddress = thread.contactAddress
        self.thread = thread
        self.sentAtTimestamp = sentAtTimestamp
        self.callAdapterType = callAdapterType
    }

    deinit {
        Logger.debug("")
        if !isEnded {
            owsFailDebug("isEnded was unexpectedly false")
        }
        if wasReportedToSystem {
            if !wasRemovedFromSystem {
                owsFailDebug("wasRemovedFromSystem was unexpectedly false")
            }
        } else {
            if wasRemovedFromSystem {
                owsFailDebug("wasRemovedFromSystem was unexpectedly true")
            }
        }
    }

    override public var description: String {
        return "IndividualCall: {\(remoteAddress), localId: \(localId), signalingId: \(callId as Optional)))}"
    }

    private func updateCallRecordType() {
        AssertIsOnMainThread()

        guard let callRecord = self.callRecord else {
            return
        }

        // Mark incomplete calls as completed if call has connected.
        if state == .connected &&
            callRecord.callType == .outgoingIncomplete {
            callRecord.updateCallType(.outgoing)
        }
        if state == .connected &&
            callRecord.callType == .incomingIncomplete {
            callRecord.updateCallType(.incoming)
        }
    }

    // MARK: Equatable

    static func == (lhs: IndividualCall, rhs: IndividualCall) -> Bool {
        return lhs.localId == rhs.localId
    }
}
