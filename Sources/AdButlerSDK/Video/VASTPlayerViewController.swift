import UIKit

/// Internal view controller for presenting the VAST player fullscreen.
internal final class VASTPlayerViewController: UIViewController {
    private let vastPlayer: AdButlerVASTPlayer
    private var closeButton: UIButton!

    init(player: AdButlerVASTPlayer) {
        self.vastPlayer = player
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        // Move player into this view
        vastPlayer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(vastPlayer)
        NSLayoutConstraint.activate([
            vastPlayer.topAnchor.constraint(equalTo: view.topAnchor),
            vastPlayer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            vastPlayer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            vastPlayer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        // Close button
        closeButton = UIButton(type: .system)
        closeButton.setTitle("✕", for: .normal)
        closeButton.titleLabel?.font = .systemFont(ofSize: 24, weight: .bold)
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        closeButton.layer.cornerRadius = 18
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        view.addSubview(closeButton)

        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            closeButton.widthAnchor.constraint(equalToConstant: 36),
            closeButton.heightAnchor.constraint(equalToConstant: 36),
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        vastPlayer.play()
    }

    @objc private func closeTapped() {
        vastPlayer.pause()
        dismiss(animated: true)
    }

    override var prefersStatusBarHidden: Bool { true }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .allButUpsideDown }
}
