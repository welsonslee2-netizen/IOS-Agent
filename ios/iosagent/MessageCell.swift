import UIKit

class MessageCell: UITableViewCell {
    private let bubbleView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.layer.cornerRadius = 18
        v.clipsToBounds = true
        return v
    }()
    
    private let messageLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 15)
        l.numberOfLines = 0
        l.lineBreakMode = .byWordWrapping
        return l
    }()
    
    private let timeLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 11)
        l.textColor = .tertiaryLabel
        return l
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let ai = UIActivityIndicatorView(style: .medium)
        ai.translatesAutoresizingMaskIntoConstraints = false
        ai.hidesWhenStopped = true
        return ai
    }()
    
    private var bubbleLeading: NSLayoutConstraint?
    private var bubbleTrailing: NSLayoutConstraint?
    private var labelLeading: NSLayoutConstraint?
    private var labelTrailing: NSLayoutConstraint?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        
        contentView.addSubview(timeLabel)
        contentView.addSubview(bubbleView)
        bubbleView.addSubview(messageLabel)
        bubbleView.addSubview(loadingIndicator)
        
        bubbleLeading = bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12)
        bubbleTrailing = bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12)
        
        labelLeading = messageLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 14)
        labelTrailing = messageLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -14)
        
        NSLayoutConstraint.activate([
            timeLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            timeLabel.heightAnchor.constraint(equalToConstant: 14),
            
            bubbleView.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 2),
            bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            bubbleView.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.82),
            
            messageLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 10),
            labelLeading!,
            labelTrailing!,
            messageLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -10),
            
            loadingIndicator.centerYAnchor.constraint(equalTo: bubbleView.centerYAnchor),
            loadingIndicator.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 14),
        ])
    }
    
    func configure(with message: Message) {
        // Parse markdown-like formatting
        messageLabel.attributedText = parseMarkdown(message.content)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        timeLabel.text = formatter.string(from: message.timestamp)
        
        if message.isLoading {
            loadingIndicator.startAnimating()
            messageLabel.text = ""
            bubbleView.backgroundColor = .secondarySystemBackground
            messageLabel.textColor = .label
            labelLeading?.isActive = false
            labelTrailing?.isActive = false
            messageLabel.leadingAnchor.constraint(equalTo: loadingIndicator.trailingAnchor, constant: 8).isActive = true
            messageLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -14).isActive = true
        } else {
            loadingIndicator.stopAnimating()
            
            switch message.role {
            case .user:
                bubbleView.backgroundColor = UIColor(red: 0.13, green: 0.59, blue: 0.95, alpha: 1.0)
                messageLabel.textColor = .white
                bubbleLeading?.isActive = false
                bubbleTrailing?.isActive = true
                timeLabel.textAlignment = .right
                timeLabelConstraints(equalTo: contentView.trailingAnchor, constant: -12)
                
            case .assistant, .system:
                bubbleView.backgroundColor = .secondarySystemBackground
                messageLabel.textColor = .label
                bubbleTrailing?.isActive = false
                bubbleLeading?.isActive = true
                timeLabel.textAlignment = .left
                timeLabelConstraints(equalTo: contentView.leadingAnchor, constant: 12)
            }
        }
    }
    
    private func timeLabelConstraints(equalTo anchor: NSLayoutXAxisAnchor, constant: CGFloat) {
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.leadingAnchor.constraint(equalTo: anchor, constant: constant).isActive = true
    }
    
    private func parseMarkdown(_ text: String) -> NSAttributedString {
        let attributed = NSMutableAttributedString(string: text)
        let fullRange = NSRange(location: 0, length: text.count)
        
        // Base attributes
        attributed.addAttribute(.font, value: UIFont.systemFont(ofSize: 15), range: fullRange)
        attributed.addAttribute(.foregroundColor, value: UIColor.label, range: fullRange)
        
        // Bold: **text**
        let boldPattern = "\\*\\*(.+?)\\*\\*"
        if let regex = try? NSRegularExpression(pattern: boldPattern) {
            let matches = regex.matches(in: text, range: fullRange)
            for match in matches.reversed() {
                if let range = Range(match.range(at: 1), in: text) {
                    let boldText = String(text[range])
                    let attrs: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 15)]
                    attributed.replaceCharacters(in: match.range, with: NSAttributedString(string: boldText, attributes: attrs))
                }
            }
        }
        
        // Code: `text`
        let codePattern = "`([^`]+)`"
        if let regex = try? NSRegularExpression(pattern: codePattern) {
            var offset = 0
            for match in regex.matches(in: text, range: fullRange) {
                let adjustedRange = NSRange(location: match.range.location - offset, length: match.range.length)
                if let swiftRange = Range(adjustedRange, in: text) {
                    let codeText = String(text[swiftRange]).replacingOccurrences(of: "`", with: "")
                    let attrs: [NSAttributedString.Key: Any] = [
                        .font: UIFont.monospacedSystemFont(ofSize: 13, weight: .regular),
                        .foregroundColor: UIColor.systemBlue,
                        .backgroundColor: UIColor.systemGray6
                    ]
                    let replacement = NSAttributedString(string: codeText, attributes: attrs)
                    attributed.replaceCharacters(in: adjustedRange, with: replacement)
                    offset += 2
                }
            }
        }
        
        return attributed
    }
}
