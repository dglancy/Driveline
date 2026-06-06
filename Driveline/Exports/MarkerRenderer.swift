//
//  MarkerRenderer.swift
//  Driveline
//
//  Created by Damien Glancy on 06/06/2026.
//

import UIKit

// MARK: - Marker renderer

struct MarkerRenderer {

  // MARK: - Actions

  func draw(at point: CGPoint, color: UIColor, systemName: String, label: String) {
    let outerRadius: CGFloat = 14
    let innerRadius: CGFloat = 11

    let outerRect = CGRect(x: point.x - outerRadius, y: point.y - outerRadius, width: outerRadius * 2, height: outerRadius * 2)
    let innerRect = CGRect(x: point.x - innerRadius, y: point.y - innerRadius, width: innerRadius * 2, height: innerRadius * 2)

    let outerPath = UIBezierPath(ovalIn: outerRect)
    UIColor.white.setFill()
    outerPath.fill()

    let innerPath = UIBezierPath(ovalIn: innerRect)
    color.setFill()
    color.setStroke()
    innerPath.lineWidth = 2
    innerPath.fill()
    innerPath.stroke()

    if let symbol = UIImage(systemName: systemName,
                            withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold))?
      .withTintColor(.white, renderingMode: .alwaysOriginal) {
      let symbolOrigin = CGPoint(x: point.x - symbol.size.width / 2,
                                 y: point.y - symbol.size.height / 2)
      symbol.draw(in: CGRect(origin: symbolOrigin, size: symbol.size))
    }

    drawLabel(label, near: point, offsetFromMarker: outerRadius)
  }

  // MARK: - Private functions

  private func drawLabel(_ text: String, near point: CGPoint, offsetFromMarker markerRadius: CGFloat) {
    let horizontalPadding: CGFloat = 8
    let verticalPadding: CGFloat = 4
    let cornerRadius: CGFloat = 8
    let verticalOffset: CGFloat = 8

    let attributes: [NSAttributedString.Key: Any] = [
      .font: UIFont.systemFont(ofSize: 12, weight: .semibold),
      .foregroundColor: UIColor.label
    ]

    let textSize = (text as NSString).size(withAttributes: attributes)
    let backgroundSize = CGSize(width: textSize.width + horizontalPadding * 2,
                                height: textSize.height + verticalPadding * 2)

    let backgroundOrigin = CGPoint(x: point.x - backgroundSize.width / 2,
                                   y: point.y + markerRadius + verticalOffset)
    let backgroundRect = CGRect(origin: backgroundOrigin, size: backgroundSize)

    let backgroundPath = UIBezierPath(roundedRect: backgroundRect, cornerRadius: cornerRadius)
    UIColor.systemBackground.setFill()
    UIColor.separator.setStroke()
    backgroundPath.lineWidth = 1
    backgroundPath.fill()
    backgroundPath.stroke()

    let textOrigin = CGPoint(x: backgroundRect.minX + horizontalPadding,
                             y: backgroundRect.minY + verticalPadding)
    (text as NSString).draw(at: textOrigin, withAttributes: attributes)
  }

}
