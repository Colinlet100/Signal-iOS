//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
//

import Foundation
import GRDBCipher
import SignalCoreKit

// NOTE: This file is generated by /Scripts/sds_codegen/sds_generate.py.
// Do not manually edit it, instead run `sds_codegen.sh`.

// MARK: - SDSSerializer

// The SDSSerializer protocol specifies how to insert and update the
// row that corresponds to this model.
class TSContactThreadSerializer: SDSSerializer {

    private let model: TSContactThread
    public required init(model: TSContactThread) {
        self.model = model
    }

    public func serializableColumnTableMetadata() -> SDSTableMetadata {
        return TSThreadSerializer.table
    }

    public func insertColumnNames() -> [String] {
        // When we insert a new row, we include the following columns:
        //
        // * "record type"
        // * "unique id"
        // * ...all columns that we set when updating.
        return [
            TSThreadSerializer.recordTypeColumn.columnName,
            uniqueIdColumnName(),
            ] + updateColumnNames()

    }

    public func insertColumnValues() -> [DatabaseValueConvertible] {
        let result: [DatabaseValueConvertible] = [
            SDSRecordType.contactThread.rawValue,
            ] + [uniqueIdColumnValue()] + updateColumnValues()
        if OWSIsDebugBuild() {
            if result.count != insertColumnNames().count {
                owsFailDebug("Update mismatch: \(result.count) != \(insertColumnNames().count)")
            }
        }
        return result
    }

    public func updateColumnNames() -> [String] {
        return [
            TSThreadSerializer.archivalDateColumn,
            TSThreadSerializer.archivedAsOfMessageSortIdColumn,
            TSThreadSerializer.conversationColorNameColumn,
            TSThreadSerializer.creationDateColumn,
            TSThreadSerializer.isArchivedByLegacyTimestampForSortingColumn,
            TSThreadSerializer.lastMessageDateColumn,
            TSThreadSerializer.messageDraftColumn,
            TSThreadSerializer.mutedUntilDateColumn,
            TSThreadSerializer.shouldThreadBeVisibleColumn,
            TSThreadSerializer.hasDismissedOffersColumn,
            ].map { $0.columnName }
    }

    public func updateColumnValues() -> [DatabaseValueConvertible] {
        let result: [DatabaseValueConvertible] = [
            self.model.archivalDate ?? DatabaseValue.null,
            self.model.archivedAsOfMessageSortId ?? DatabaseValue.null,
            self.model.conversationColorName.rawValue,
            self.model.creationDate,
            self.model.isArchivedByLegacyTimestampForSorting,
            self.model.lastMessageDate ?? DatabaseValue.null,
            self.model.messageDraft ?? DatabaseValue.null,
            self.model.mutedUntilDate ?? DatabaseValue.null,
            self.model.shouldThreadBeVisible,
            self.model.hasDismissedOffers,

        ]
        if OWSIsDebugBuild() {
            if result.count != updateColumnNames().count {
                owsFailDebug("Update mismatch: \(result.count) != \(updateColumnNames().count)")
            }
        }
        return result
    }

    public func uniqueIdColumnName() -> String {
        return TSThreadSerializer.uniqueIdColumn.columnName
    }

    // TODO: uniqueId is currently an optional on our models.
    //       We should probably make the return type here String?
    public func uniqueIdColumnValue() -> DatabaseValueConvertible {
        // FIXME remove force unwrap
        return model.uniqueId!
    }
}
