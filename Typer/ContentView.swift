import SwiftUI
import Cocoa
import ApplicationServices

// MARK: - Typing Styles
enum TypingStyle: String, CaseIterable, Identifiable {
    case normal = "Normal"
    case fastPro = "Fast"
    case sloppy = "Sloppy"
    var id: String { rawValue }
}

// MARK: - ContentView
struct ContentView: View {

    @State private var inputText = ""
    @State private var typingSpeed: Double = 0.5
    @State private var isTyping = false
    @State private var countdown = 10
    @State private var showCountdown = false
    @State private var cancelled = false
    @State private var typingStyle: TypingStyle = .normal
    @State private var rewrittenPreview = ""
    @State private var countdownInput = "10"

    // Simple synonym dictionary
    let dictionary: [String: [String]] = [
        "good": ["excellent", "great", "superb", "amazing"],
        "bad": ["poor", "terrible", "awful"],
        "happy": ["joyful", "cheerful", "elated"],
        "sad": ["unhappy", "miserable", "downcast"],
        "big": ["large", "huge", "massive"],
        "small": ["tiny", "mini", "compact"],
        "make": ["create", "build", "produce"],
        "see": ["observe", "notice", "spot"],
        "think": ["believe", "consider", "ponder"],
        "use": ["utilize", "apply", "deploy"],
        "very": ["extremely", "highly", "deeply"]
    ]

    var body: some View {
        VStack(spacing: 18) {

            Text("Typer")
                .font(.largeTitle)
                .bold()

            TextEditor(text: $inputText)
                .frame(height: 150)
                .border(.gray)

            if !rewrittenPreview.isEmpty {
                VStack(alignment: .leading) {
                    Text("Rewritten Preview")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Text(rewrittenPreview)
                        .padding(6)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(8)
                }
            }

            Picker("Style", selection: $typingStyle) {
                ForEach(TypingStyle.allCases) { style in
                    Text(style.rawValue)
                }
            }
            .pickerStyle(.segmented)

            HStack {
                Text("Speed")
                Slider(value: $typingSpeed, in: 0.1...1.0)
                Text(String(format: "%.2f", typingSpeed))
            }

            HStack {
                Text("Countdown")
                TextField("Seconds", text: $countdownInput)
                    .frame(width: 60)
                    .textFieldStyle(.roundedBorder)
            }

            if showCountdown {
                Text("Starting in \(countdown)...")
                    .font(.title2)
                    .foregroundColor(.orange)
            }

            HStack {
                Button("Start Typing") {
                    startCountdown()
                }
                .disabled(isTyping)

                Button("Stop") {
                    cancelled = true
                    isTyping = false
                    showCountdown = false
                }

                Button("Rewrite") {
                    rewrittenPreview = rewriteText(inputText)
                }

                Button("Apply Rewrite") {
                    if !rewrittenPreview.isEmpty {
                        inputText = rewrittenPreview
                        rewrittenPreview = ""
                    }
                }
            }

            Spacer()
        }
        .padding()
        .preferredColorScheme(.dark)
        .onAppear {
            NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                if event.keyCode == 53 { // ESC
                    cancelled = true
                    isTyping = false
                    showCountdown = false
                    return nil
                }
                return event
            }
        }
    }

    // MARK: - Countdown
    func startCountdown() {
        cancelled = false
        countdown = max(1, Int(countdownInput) ?? 10)
        showCountdown = true

        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            countdown -= 1
            if countdown <= 0 || cancelled {
                timer.invalidate()
                showCountdown = false
                guard !cancelled else { return }

                isTyping = true
                typeText(
                    inputText,
                    speed: typingSpeed,
                    style: typingStyle,
                    cancelled: { cancelled }
                ) {
                    isTyping = false
                }
            }
        }
    }

    // MARK: - Rewrite Logic (fixed suffix/prefix)
    func rewriteText(_ text: String) -> String {
        let words = text.split(separator: " ")
        var result: [String] = []

        for wordSub in words {
            let word = String(wordSub) // Convert Substring → String
            let trimmed = word.trimmingCharacters(in: .punctuationCharacters)
            let lower = trimmed.lowercased()

            if let options = dictionary[lower], Bool.random() {
                var replacement = options.randomElement()!

                // Preserve capitalization
                if trimmed.first?.isUppercase == true {
                    replacement = replacement.capitalized
                }

                // Preserve punctuation
                let prefix = String(word.prefix { $0.isPunctuation })
                let suffix = String(word.reversed().prefix { $0.isPunctuation }.reversed())

                result.append(prefix + replacement + suffix)
            } else {
                result.append(word)
            }
        }

        return result.joined(separator: " ")
    }

    // MARK: - Typing Engine
    func typeText(
        _ text: String,
        speed: Double,
        style: TypingStyle,
        cancelled: @escaping () -> Bool,
        completion: @escaping () -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            for char in text {
                if cancelled() { break }

                postKey(char)

                var delay = speed
                switch style {
                case .normal:
                    delay += Double.random(in: 0.02...0.08)
                case .fastPro:
                    delay *= 0.6
                    delay += Double.random(in: 0.01...0.03)
                case .sloppy:
                    delay += Double.random(in: 0.05...0.15)
                    if Int.random(in: 0...12) == 0 {
                        Thread.sleep(forTimeInterval: Double.random(in: 0.2...0.5))
                    }
                }

                Thread.sleep(forTimeInterval: delay)
            }

            DispatchQueue.main.async {
                completion()
            }
        }
    }

    // MARK: - Key Posting
    func postKey(_ character: Character) {
        let string = String(character)
        let utf16 = Array(string.utf16)

        guard !utf16.isEmpty else { return }

        let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true)
        keyDown?.keyboardSetUnicodeString(
            stringLength: utf16.count,
            unicodeString: utf16
        )

        let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: false)
        keyUp?.keyboardSetUnicodeString(
            stringLength: utf16.count,
            unicodeString: utf16
        )

        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
}
