import UIKit
import Speech
import AVKit
import Foundation

class ViewController: UIViewController, AVAudioPlayerDelegate, SFSpeechRecognizerDelegate {

    @IBOutlet weak var txtViewTranscipt: UITextView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var audioFileNameLabel: UILabel! // オーディオファイル名を表示するUILabel

    var audioPlayer: AVAudioPlayer!
    var audioFiles: [URL] = [] // 音声ファイルのURLを格納する配列
    var currentAudioIndex = 0
    let delayDuration: TimeInterval = 1.0 // ディレイの秒数（例：1秒）

    // 音声認識エンジンを初期化
    let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP")) // 使用する言語に合わせて変更

    override func viewDidLoad() {
        super.viewDidLoad()
        loadAudioFiles()

        // 音声認識のデリゲートを設定
        speechRecognizer?.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func loadAudioFiles() {
        // プロジェクト内の指定ディレクトリから音声ファイルを読み込む
        if let audioDirectoryURL = Bundle.main.resourceURL?.appendingPathComponent("samples") {
            do {
                let audioFileURLs = try FileManager.default.contentsOfDirectory(at: audioDirectoryURL, includingPropertiesForKeys: nil, options: [])
                audioFiles = audioFileURLs.filter { $0.pathExtension == "wav" } // .wavファイルをフィルタリング
            } catch {
                print("Error loading audio files: \(error)")
            }
        }
    }

    func requestSpeechAuth() {
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
            if authStatus == SFSpeechRecognizerAuthorizationStatus.authorized {
                if self.currentAudioIndex < self.audioFiles.count {
                    let audioFileURL = self.audioFiles[self.currentAudioIndex]
                    do {
                        let audio = try AVAudioPlayer(contentsOf: audioFileURL)
                        self.audioPlayer = audio
                        self.audioPlayer.play()
                        self.audioPlayer.delegate = self
                    } catch {
                        print("Error: \(error)")
                    }
                    let recognizer = SFSpeechRecognizer()
                    let request = SFSpeechURLRecognitionRequest(url: audioFileURL)

                    recognizer?.recognitionTask(with: request, resultHandler: { (result, error) in
                        if let err = error {
                            print("There was an error: \(err)")
                        } else {
                            self.txtViewTranscipt.text = result?.bestTranscription.formattedString
                            // 特定のワードをチェック
                            if let recognizedText = result?.bestTranscription.formattedString,
                               recognizedText.contains("Hey Siri") {
                                // オーディオファイル名をprint
                                print("Now Playing: \(audioFileURL.lastPathComponent)")
                            }
                        }
                    })
                    // オーディオファイル名を更新
                    self.updateAudioFileNameLabel(name: audioFileURL.lastPathComponent)
                } else {
                    // All audio files have been played
                    print("All audio files have been played.")
                }
            }
        }
    }

    @IBAction func playBtnPressed(_ sender: Any) {
        self.activityIndicator.startAnimating()
        self.requestSpeechAuth()
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        self.activityIndicator.stopAnimating()
        self.currentAudioIndex += 1
        if self.currentAudioIndex < self.audioFiles.count {
            // ディレイを挿入して次のオーディオファイル再生まで待機
            DispatchQueue.main.asyncAfter(deadline: .now() + delayDuration) {
                self.requestSpeechAuth()
            }
        } else {
            // All audio files have been played
            print("All audio files have been played.")
        }
    }

    // オーディオファイル名を更新するメソッド
    func updateAudioFileNameLabel(name: String) {
        DispatchQueue.main.async {
            if let audioFileNameLabel = self.audioFileNameLabel {
                audioFileNameLabel.text = "Now Playing: \(name)"
            } else {
                // audioFileNameLabelがnilの場合、何も表示しない
            }
        }
    }
}

