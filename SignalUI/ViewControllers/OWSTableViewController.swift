//
//  Copyright (c) 2022 Open Whisper Systems. All rights reserved.
//

import Foundation
import SignalMessaging

@objc
public extension OWSTableItem {

    static var primaryLabelFont: UIFont {
        return UIFont.ows_dynamicTypeBodyClamped
    }

    static var accessoryLabelFont: UIFont {
        return UIFont.ows_dynamicTypeBodyClamped
    }

    static var iconSpacing: CGFloat { 16 }
    static var iconSize: CGFloat { 24 }

    static func buildCell(name: String, iconView: UIView) -> UITableViewCell {
        return buildCell(name: name, iconView: iconView, iconSpacing: self.iconSpacing)
    }

    static func buildCell(name: String, iconView: UIView, iconSpacing: CGFloat) -> UITableViewCell {
        assert(name.count > 0)

        let cell = OWSTableItem.newCell()
        cell.preservesSuperviewLayoutMargins = true
        cell.contentView.preservesSuperviewLayoutMargins = true

        let rowLabel = UILabel()
        rowLabel.text = name
        rowLabel.textColor = Theme.primaryTextColor
        rowLabel.font = OWSTableItem.primaryLabelFont
        rowLabel.lineBreakMode = .byTruncatingTail

        let contentRow = UIStackView(arrangedSubviews: [ iconView, rowLabel ])
        contentRow.spacing = iconSpacing

        cell.contentView.addSubview(contentRow)
        contentRow.autoPinEdgesToSuperviewMargins()

        return cell
    }

    static func imageView(forIcon icon: ThemeIcon,
                          tintColor: UIColor? = nil,
                          iconSize: CGFloat = iconSize) -> UIImageView {
        let iconImage = Theme.iconImage(icon)
        let iconView = UIImageView(image: iconImage)
        iconView.tintColor = tintColor ?? Theme.primaryIconColor
        iconView.contentMode = .scaleAspectFit
        iconView.layer.minificationFilter = .trilinear
        iconView.layer.magnificationFilter = .trilinear
        iconView.autoSetDimensions(to: CGSize(square: iconSize))
        return iconView
    }

    static func buildCell(name: String,
                          icon: ThemeIcon,
                          accessibilityIdentifier: String? = nil) -> UITableViewCell {
        let iconView = imageView(forIcon: icon)
        let cell = buildCell(name: name, iconView: iconView)
        cell.accessibilityIdentifier = accessibilityIdentifier
        return cell
    }

    static func buildDisclosureCell(name: String,
                                    icon: ThemeIcon,
                                    accessibilityIdentifier: String) -> UITableViewCell {
        let cell = buildCell(name: name, icon: icon)
        cell.accessoryType = .disclosureIndicator
        cell.accessibilityIdentifier = accessibilityIdentifier
        return cell
    }

    static func buildLabelCell(name: String,
                               icon: ThemeIcon,
                               accessibilityIdentifier: String) -> UITableViewCell {
        let cell = buildCell(name: name, icon: icon)
        cell.accessoryType = .none
        cell.accessibilityIdentifier = accessibilityIdentifier
        return cell
    }

    @available(swift, obsoleted: 1.0)
    static func disclosureItem(icon: ThemeIcon,
                               name: String,
                               accessoryText: String? = nil,
                               accessibilityIdentifier: String,
                               actionBlock: (() -> Void)?) -> OWSTableItem {
        item(icon: icon,
             name: name,
             accessoryText: accessoryText,
             accessoryType: .disclosureIndicator,
             accessibilityIdentifier: accessibilityIdentifier,
             actionBlock: actionBlock)
    }

    @nonobjc
    static func disclosureItem(icon: ThemeIcon,
                               name: String,
                               maxNameLines: Int? = nil,
                               accessoryText: String? = nil,
                               accessibilityIdentifier: String,
                               actionBlock: (() -> Void)?) -> OWSTableItem {
        item(icon: icon,
             name: name,
             maxNameLines: maxNameLines,
             accessoryText: accessoryText,
             accessoryType: .disclosureIndicator,
             accessibilityIdentifier: accessibilityIdentifier,
             actionBlock: actionBlock)
    }

    @nonobjc
    static func actionItem(icon: ThemeIcon? = nil,
                           tintColor: UIColor? = nil,
                           name: String,
                           textColor: UIColor? = nil,
                           accessoryText: String? = nil,
                           accessoryImage: UIImage? = nil,
                           accessibilityIdentifier: String,
                           actionBlock: (() -> Void)?) -> OWSTableItem {
        item(icon: icon,
             tintColor: tintColor,
             name: name,
             textColor: textColor,
             accessoryText: accessoryText,
             accessoryImage: accessoryImage,
             accessibilityIdentifier: accessibilityIdentifier,
             actionBlock: actionBlock)
    }

    @nonobjc
    static func item(icon: ThemeIcon? = nil,
                     tintColor: UIColor? = nil,
                     name: String,
                     maxNameLines: Int? = nil,
                     textColor: UIColor? = nil,
                     accessoryText: String? = nil,
                     accessoryType: UITableViewCell.AccessoryType = .none,
                     accessoryImage: UIImage? = nil,
                     accessoryView: UIView? = nil,
                     accessibilityIdentifier: String,
                     actionBlock: (() -> Void)? = nil) -> OWSTableItem {

        OWSTableItem(customCellBlock: {
            OWSTableItem.buildCellWithAccessoryLabel(
            icon: icon,
            tintColor: tintColor,
            itemName: name,
            maxItemNameLines: maxNameLines,
            textColor: textColor,
            accessoryText: accessoryText,
            accessoryType: accessoryType,
            accessoryImage: accessoryImage,
            accessoryView: accessoryView,
            accessibilityIdentifier: accessibilityIdentifier
            )
        },
                     actionBlock: actionBlock)
    }

    @available(swift, obsoleted: 1.0)
    static func buildCellWithAccessoryLabel(itemName: String,
                                            textColor: UIColor?,
                                            accessoryText: String?,
                                            accessoryType: UITableViewCell.AccessoryType,
                                            accessoryImage: UIImage?,
                                            accessibilityIdentifier: String?) -> UITableViewCell {
        buildIconNameCell(itemName: itemName,
                          textColor: textColor,
                          accessoryText: accessoryText,
                          accessoryType: accessoryType,
                          accessoryImage: accessoryImage,
                          accessibilityIdentifier: accessibilityIdentifier)
    }

    @nonobjc
    static func buildCellWithAccessoryLabel(icon: ThemeIcon? = nil,
                                            tintColor: UIColor? = nil,
                                            itemName: String,
                                            maxItemNameLines: Int? = nil,
                                            textColor: UIColor? = nil,
                                            accessoryText: String? = nil,
                                            accessoryType: UITableViewCell.AccessoryType = .disclosureIndicator,
                                            accessoryImage: UIImage? = nil,
                                            accessoryView: UIView? = nil,
                                            accessibilityIdentifier: String? = nil) -> UITableViewCell {
        buildIconNameCell(icon: icon,
                          tintColor: tintColor,
                          itemName: itemName,
                          maxItemNameLines: maxItemNameLines,
                          textColor: textColor,
                          accessoryText: accessoryText,
                          accessoryType: accessoryType,
                          accessoryImage: accessoryImage,
                          accessoryView: accessoryView,
                          accessibilityIdentifier: accessibilityIdentifier)
    }

    @nonobjc
    static func buildIconNameCell(icon: ThemeIcon? = nil,
                                  tintColor: UIColor? = nil,
                                  itemName: String,
                                  maxItemNameLines: Int? = nil,
                                  textColor: UIColor? = nil,
                                  accessoryText: String? = nil,
                                  accessoryTextColor: UIColor? = nil,
                                  accessoryType: UITableViewCell.AccessoryType = .none,
                                  accessoryImage: UIImage? = nil,
                                  accessoryView: UIView? = nil,
                                  customColor: UIColor? = nil,
                                  accessibilityIdentifier: String? = nil) -> UITableViewCell {

        // We can't use the built-in UITableViewCell with CellStyle.value1,
        // because if the content of the primary label and the accessory label
        // overflow the cell layout, their contents will overlap.  We want
        // the labels to truncate in that scenario.
        let cell = OWSTableItem.newCell()
        cell.preservesSuperviewLayoutMargins = true
        cell.contentView.preservesSuperviewLayoutMargins = true

        var subviews = [UIView]()

        if let icon = icon {
            let iconView = self.imageView(forIcon: icon, tintColor: customColor ?? tintColor, iconSize: iconSize)
            iconView.setCompressionResistanceHorizontalHigh()
            subviews.append(iconView)
        }

        let nameLabel = UILabel()
        nameLabel.text = itemName
        if let textColor = textColor {
            nameLabel.textColor = textColor
        } else {
            nameLabel.textColor = Theme.primaryTextColor
        }
        nameLabel.font = OWSTableItem.primaryLabelFont
        nameLabel.adjustsFontForContentSizeCategory = true

        // Having two side-by-side multi-line labels makes
        // autolayout *really* confused because it doesn't
        // seem to know which height to respect (if they are
        // of different intrinsic height). It leads to lots of
        // very strange indeterminant behavior. To work around,
        // we only allow the longer of the two labels to be
        // multi-line.
        if let maxItemNameLines = maxItemNameLines {
            nameLabel.numberOfLines = maxItemNameLines
            nameLabel.lineBreakMode = .byTruncatingTail
        } else if itemName.count >= (accessoryText ?? "").count {
            nameLabel.numberOfLines = 0
            nameLabel.lineBreakMode = .byWordWrapping
        } else {
            nameLabel.numberOfLines = 1
            nameLabel.lineBreakMode = .byTruncatingTail
        }

        nameLabel.setContentHuggingLow()
        nameLabel.setCompressionResistanceHigh()
        subviews.append(nameLabel)
        if let customColor = customColor {
            nameLabel.textColor = customColor
        }

        if let accessoryView = accessoryView {
            owsAssertDebug(accessoryText == nil)

            subviews.append(accessoryView)
        } else if let accessoryText = accessoryText {
            let accessoryLabel = UILabel()
            accessoryLabel.text = accessoryText
            accessoryLabel.textColor = accessoryTextColor ?? (Theme.isDarkThemeEnabled ? .ows_gray25 : .ows_gray45)
            accessoryLabel.font = OWSTableItem.accessoryLabelFont
            accessoryLabel.adjustsFontForContentSizeCategory = true

            if itemName.count >= accessoryText.count {
                accessoryLabel.numberOfLines = 1
                accessoryLabel.lineBreakMode = .byTruncatingTail
            } else {
                accessoryLabel.numberOfLines = 0
                accessoryLabel.lineBreakMode = .byWordWrapping
            }

            accessoryLabel.setCompressionResistanceHigh()
            accessoryLabel.setContentHuggingHorizontalHigh()
            accessoryLabel.setContentHuggingVerticalLow()
            subviews.append(accessoryLabel)
        }

        let contentRow = UIStackView(arrangedSubviews: subviews)
        contentRow.axis = .horizontal
        contentRow.alignment = .center
        contentRow.spacing = self.iconSpacing
        cell.contentView.addSubview(contentRow)

        contentRow.setContentHuggingHigh()
        contentRow.autoPinEdgesToSuperviewMargins()
        contentRow.autoSetDimension(.height, toSize: iconSize, relation: .greaterThanOrEqual)

        cell.accessibilityIdentifier = accessibilityIdentifier

        if let accessoryImage = accessoryImage {
            let accessoryImageView = UIImageView()
            accessoryImageView.setTemplateImage(
                accessoryImage,
                // Match the OS accessory view colors
                tintColor: Theme.isDarkThemeEnabled ? .ows_whiteAlpha25 : .ows_blackAlpha25
            )
            accessoryImageView.sizeToFit()
            cell.accessoryView = accessoryImageView
        } else {
            cell.accessoryType = accessoryType
        }

        return cell
    }

    static func buildIconInCircleView(icon: ThemeIcon,
                                      innerIconSize: CGFloat) -> UIView {
        return buildIconInCircleView(icon: icon,
                                     iconSize: nil,
                                     innerIconSize: innerIconSize,
                                     iconTintColor: nil)
    }

    static func buildIconInCircleView(icon: ThemeIcon,
                                      innerIconSize: CGFloat,
                                      iconTintColor: UIColor) -> UIView {
        return buildIconInCircleView(icon: icon,
                                     iconSize: nil,
                                     innerIconSize: innerIconSize,
                                     iconTintColor: iconTintColor)
    }
}

// MARK: -

public extension OWSTableItem {
    static func buildIconInCircleView(icon: ThemeIcon,
                                      iconSize iconSizeParam: UInt? = nil,
                                      innerIconSize innerIconSizeParam: CGFloat? = nil,
                                      iconTintColor: UIColor? = nil) -> UIView {
        let iconSize = CGFloat(iconSizeParam ?? AvatarBuilder.standardAvatarSizePoints)
        let innerIconSize: CGFloat
        if let innerIconSizeParam = innerIconSizeParam {
            innerIconSize = innerIconSizeParam
        } else {
            innerIconSize = CGFloat(iconSize) * 0.6
        }
        let iconView = OWSTableItem.imageView(forIcon: icon, tintColor: iconTintColor ?? Theme.accentBlueColor, iconSize: innerIconSize)
        let iconWrapper = UIView.container()
        iconWrapper.addSubview(iconView)
        iconView.autoCenterInSuperview()
        iconWrapper.backgroundColor = Theme.isDarkThemeEnabled ? .ows_gray65 : .ows_gray02
        iconWrapper.layer.cornerRadius = iconSize * 0.5
        iconWrapper.autoSetDimensions(to: CGSize(square: iconSize))
        iconWrapper.setCompressionResistanceHigh()
        iconWrapper.setContentHuggingHigh()
        return iconWrapper
    }

    // Factory method for rows that display a labeled value.
    // The value can be copied to the pasteboard by tapping.
    static func copyableItem(label: String,
                             value displayValue: String?,
                             pasteboardValue: String? = nil,
                             accessibilityIdentifier: String? = nil) -> OWSTableItem {
        // If there is a custom pasteboardValue, honor it.
        // Otherwise just default to using the displayValue.
        let pasteboardValue = pasteboardValue ?? displayValue
        let accessibilityIdentifier = accessibilityIdentifier ?? label
        let displayValue = displayValue ?? OWSLocalizedString("MISSING_VALUE",
                                                             comment: "Generic indicator that no value is available for display")
        return .item(
            name: label,
            accessoryText: displayValue,
            accessibilityIdentifier: accessibilityIdentifier,
            actionBlock: {
                if let pasteboardValue = pasteboardValue {
                    UIPasteboard.general.string = pasteboardValue
                }

                guard let fromVC = CurrentAppContext().frontmostViewController() else {
                    owsFailDebug("could not identify frontmostViewController")
                    return
                }
                let toast = OWSLocalizedString("COPIED_TO_CLIPBOARD",
                                              comment: "Indicator that a value has been copied to the clipboard.")
                fromVC.presentToast(text: toast)

            }
        )
    }

    static func configureCell(_ cell: UITableViewCell, isSplitViewControllerExpanded: Bool) {
        Self.configureCell(cell)
        cell.selectedBackgroundView?.backgroundColor = isSplitViewControllerExpanded ? Theme.tableCell2SelectedBackgroundColor2 : Theme.tableCell2SelectedBackgroundColor
        cell.backgroundColor = isSplitViewControllerExpanded ? Theme.secondaryBackgroundColor : Theme.backgroundColor
        cell.multipleSelectionBackgroundView?.backgroundColor = Theme.tableCell2MultiSelectedBackgroundColor
    }
}

// MARK: - Declarative Initializers

public extension OWSTableContents {

    convenience init(title: String? = nil,
                     sections: [OWSTableSection] = []) {
        self.init()
        if let title = title {
            self.title = title
        }
        sections.forEach { section in
            self.addSection(section)
        }
    }

}

public extension OWSTableSection {

    convenience init(title: String? = nil,
                     items: [OWSTableItem] = [],
                     footerTitle: String? = nil) {

        self.init(title: title, items: items)
        self.footerTitle = footerTitle
    }

    convenience init(title: String? = nil,
                     header: UIView? = nil,
                     items: [OWSTableItem] = [],
                     footer: UIView? = nil) {

        self.init(title: title, items: items)
        self.customHeaderView = header
        self.customFooterView = footer
    }

    convenience init(title: String? = nil,
                     header: (() -> UIView?) = {nil},
                     items: [OWSTableItem] = [],
                     footer: (() -> UIView?) = {nil}) {
        self.init(title: title,
                  header: header(),
                  items: items,
                  footer: footer())
    }
}
