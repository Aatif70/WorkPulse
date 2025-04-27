import UIKit
import PDFKit

class SessionPDFRenderer {
    private let sessions: [Session]
    private let dateString: String
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
    
    init(sessions: [Session], date: String) {
        self.sessions = sessions
        self.dateString = date
    }
    
    func renderPDF() -> Data? {
        // Create a PDF document
        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8)  // A4 size in points
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            // Add logo and header
            addHeader(pageRect: pageRect)
            
            // Add date and totals
            addDateSummary(pageRect: pageRect)
            
            // Add session table
            addSessionsTable(pageRect: pageRect)
        }
        
        return data
    }
    
    private func addHeader(pageRect: CGRect) {
        let titleFont = UIFont.systemFont(ofSize: 24, weight: .bold)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: UIColor.black
        ]
        
        let title = "WorkPulse Session Report"
        let titleStringSize = title.size(withAttributes: titleAttributes)
        
        let titleRect = CGRect(
            x: (pageRect.width - titleStringSize.width) / 2.0,
            y: 60,
            width: titleStringSize.width,
            height: titleStringSize.height
        )
        
        title.draw(in: titleRect, withAttributes: titleAttributes)
        
        // Add divider line
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 40, y: titleRect.maxY + 20))
        path.addLine(to: CGPoint(x: pageRect.width - 40, y: titleRect.maxY + 20))
        path.lineWidth = 1.0
        UIColor.lightGray.setStroke()
        path.stroke()
    }
    
    private func addDateSummary(pageRect: CGRect) {
        let font = UIFont.systemFont(ofSize: 14)
        let boldFont = UIFont.boldSystemFont(ofSize: 14)
        
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.black
        ]
        
        let boldAttributes: [NSAttributedString.Key: Any] = [
            .font: boldFont,
            .foregroundColor: UIColor.black
        ]
        
        // Date heading
        let dateHeading = "Date: "
        let dateHeadingSize = dateHeading.size(withAttributes: boldAttributes)
        
        let dateRect = CGRect(
            x: 40,
            y: 120,
            width: dateHeadingSize.width,
            height: dateHeadingSize.height
        )
        
        dateHeading.draw(in: dateRect, withAttributes: boldAttributes)
        
        // Date value
        let dateValue = dateString
        let dateValueRect = CGRect(
            x: dateRect.maxX,
            y: 120,
            width: 200,
            height: dateHeadingSize.height
        )
        
        dateValue.draw(in: dateValueRect, withAttributes: textAttributes)
        
        // Total sessions
        let totalSessionsHeading = "Total Sessions: "
        let totalSessionsRect = CGRect(
            x: 40,
            y: dateRect.maxY + 10,
            width: 150,
            height: dateHeadingSize.height
        )
        
        totalSessionsHeading.draw(in: totalSessionsRect, withAttributes: boldAttributes)
        
        let totalSessionsValue = "\(sessions.count)"
        let totalSessionsValueRect = CGRect(
            x: totalSessionsRect.maxX,
            y: totalSessionsRect.minY,
            width: 50,
            height: dateHeadingSize.height
        )
        
        totalSessionsValue.draw(in: totalSessionsValueRect, withAttributes: textAttributes)
        
        // Total time
        let totalTime = sessions.compactMap { $0.duration }.reduce(0, +)
        let totalTimeHeading = "Total Time: "
        let totalTimeRect = CGRect(
            x: 40,
            y: totalSessionsRect.maxY + 10,
            width: 150,
            height: dateHeadingSize.height
        )
        
        totalTimeHeading.draw(in: totalTimeRect, withAttributes: boldAttributes)
        
        let totalTimeValue = totalTime.formatAsHoursMinutesSeconds()
        let totalTimeValueRect = CGRect(
            x: totalTimeRect.maxX,
            y: totalTimeRect.minY,
            width: 100,
            height: dateHeadingSize.height
        )
        
        totalTimeValue.draw(in: totalTimeValueRect, withAttributes: textAttributes)
    }
    
    private func addSessionsTable(pageRect: CGRect) {
        let startY: CGFloat = 200
        let rowHeight: CGFloat = 25
        let padding: CGFloat = 10
        
        let col1X: CGFloat = 40    // Start Time
        let col2X: CGFloat = 180   // End Time
        let col3X: CGFloat = 320   // Duration
        let col4X: CGFloat = 440   // Type
        
        let headerFont = UIFont.boldSystemFont(ofSize: 12)
        let cellFont = UIFont.systemFont(ofSize: 12)
        
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: headerFont,
            .foregroundColor: UIColor.black
        ]
        
        let cellAttributes: [NSAttributedString.Key: Any] = [
            .font: cellFont,
            .foregroundColor: UIColor.black
        ]
        
        // Draw table header
        let headers = ["Start Time", "End Time", "Duration", "Type"]
        let headerPositions = [col1X, col2X, col3X, col4X]
        
        for (i, header) in headers.enumerated() {
            let headerRect = CGRect(
                x: headerPositions[i],
                y: startY,
                width: 140,
                height: rowHeight
            )
            
            header.draw(in: headerRect, withAttributes: headerAttributes)
        }
        
        // Draw header underline
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 40, y: startY + rowHeight))
        path.addLine(to: CGPoint(x: pageRect.width - 40, y: startY + rowHeight))
        path.lineWidth = 0.5
        UIColor.gray.setStroke()
        path.stroke()
        
        // Draw rows
        var yPosition = startY + rowHeight + padding
        
        for session in sessions.sorted(by: { $0.startTime > $1.startTime }) {
            let startTime = dateFormatter.string(from: session.startTime)
            let endTime = session.endTime != nil ? dateFormatter.string(from: session.endTime!) : "In Progress"
            let duration = session.formattedDuration
            let type = session.isManualEntry ? "Manual" : "Automatic"
            
            let rowData = [startTime, endTime, duration, type]
            
            for (i, text) in rowData.enumerated() {
                let cellRect = CGRect(
                    x: headerPositions[i],
                    y: yPosition,
                    width: 140,
                    height: rowHeight
                )
                
                text.draw(in: cellRect, withAttributes: cellAttributes)
            }
            
            // Draw row divider if not the last row
            if session != sessions.last {
                let linePath = UIBezierPath()
                linePath.move(to: CGPoint(x: 40, y: yPosition + rowHeight))
                linePath.addLine(to: CGPoint(x: pageRect.width - 40, y: yPosition + rowHeight))
                linePath.lineWidth = 0.2
                UIColor.lightGray.setStroke()
                linePath.stroke()
            }
            
            yPosition += rowHeight + 5
        }
        
        // Draw footer
        let footerFont = UIFont.systemFont(ofSize: 10)
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: footerFont,
            .foregroundColor: UIColor.gray
        ]
        
        let footer = "Generated by WorkPulse on \(Date().formatted(.dateTime))"
        let footerRect = CGRect(
            x: 40,
            y: pageRect.height - 40,
            width: pageRect.width - 80,
            height: 20
        )
        
        footer.draw(in: footerRect, withAttributes: footerAttributes)
    }
} 