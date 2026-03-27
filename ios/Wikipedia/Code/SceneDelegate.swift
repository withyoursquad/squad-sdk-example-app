import UIKit
import BackgroundTasks
import CocoaLumberjackSwift
import SquadSportsSDK

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
#if TEST
// Avoids loading needless dependencies during unit tests
    var window: UIWindow?
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: windowScene)
        self.window = window
        
        window.rootViewController = UIViewController()
        window.makeKeyAndVisible()
    }
    
#else

    var window: UIWindow?
    private var appNeedsResume = true

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {

        guard let windowScene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: windowScene)
        self.window = window
        
        guard let appViewController else {
            return
        }
        
        // scene(_ scene: UIScene, continue userActivity: NSUserActivity) and
        // scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>)
        // windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void)
        // are not called upon terminated state, so we need to handle them explicitly here.
        if let userActivity = connectionOptions.userActivities.first {
            processUserActivity(userActivity)
        } else if !connectionOptions.urlContexts.isEmpty {
            openURLContexts(connectionOptions.urlContexts)
        } else if let shortcutItem = connectionOptions.shortcutItem {
            processShortcutItem(shortcutItem)
        }
        
        UNUserNotificationCenter.current().delegate = appViewController
        appViewController.launchApp(in: window, waitToResumeApp: appNeedsResume)

        // Squad: add a floating button to launch the experience
        addSquadButton(to: window)
    }

    private func addSquadButton(to window: UIWindow) {
        let button = UIButton(type: .system)
        button.setTitle("Squad", for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 15)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(red: 0.2, green: 0.6, blue: 1.0, alpha: 1.0)
        button.layer.cornerRadius = 24
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowOpacity = 0.3
        button.layer.shadowRadius = 4
        button.frame = CGRect(x: 0, y: 0, width: 80, height: 48)
        button.addTarget(self, action: #selector(squadButtonTapped), for: .touchUpInside)

        window.addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.trailingAnchor.constraint(equalTo: window.trailingAnchor, constant: -20),
            button.bottomAnchor.constraint(equalTo: window.safeAreaLayoutGuide.bottomAnchor, constant: -70),
            button.widthAnchor.constraint(equalToConstant: 80),
            button.heightAnchor.constraint(equalToConstant: 48),
        ])
    }

    @objc private func squadButtonTapped() {
        guard SquadSDK.isInitialized,
              let rootVC = window?.rootViewController else { return }
        let squadVC = SquadSDK.shared.createExperienceViewController()
        rootVC.present(squadVC, animated: true)
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {

    }

    func sceneDidBecomeActive(_ scene: UIScene) {

        resumeAppIfNecessary()
    }

    func sceneWillResignActive(_ scene: UIScene) {

        UserDefaults.standard.wmf_setAppResignActiveDate(Date())
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        appDelegate?.cancelPendingBackgroundTasks()
    }

    func sceneDidEnterBackground(_ scene: UIScene) {

        appDelegate?.updateDynamicIconShortcutItems()
        appDelegate?.scheduleBackgroundAppRefreshTask()
        appDelegate?.scheduleDatabaseHousekeeperTask()
    }
    
    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        processShortcutItem(shortcutItem, completionHandler: completionHandler)
    }
    
    private func processShortcutItem(_ shortcutItem: UIApplicationShortcutItem, completionHandler: ((Bool) -> Void)? = nil) {
        appViewController?.processShortcutItem(shortcutItem) { handled in
            completionHandler?(handled)
        }
    }
    
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        processUserActivity(userActivity)
    }
    
    private func processUserActivity(_ userActivity: NSUserActivity) {
        guard let appViewController else {
            return
        }
        
        appViewController.showSplashView()
        var userInfo = userActivity.userInfo
        userInfo?[WMFRoutingUserInfoKeys.source] = WMFRoutingUserInfoSourceValue.deepLinkRawValue
        userActivity.userInfo = userInfo
        
        _ = appViewController.processUserActivity(userActivity, animated: false) { [weak self] in

            guard let self else {
                return
            }
            
            if appNeedsResume {
                resumeAppIfNecessary()
            } else {
                appViewController.hideSplashView()
            }
        }
    }
    
    func scene(_ scene: UIScene, didFailToContinueUserActivityWithType userActivityType: String, error: any Error) {
        DDLogDebug("didFailToContinueUserActivityWithType: \(userActivityType) error: \(error)")
    }
    
    func scene(_ scene: UIScene, didUpdate userActivity: NSUserActivity) {
        DDLogDebug("didUpdateUserActivity: \(userActivity)")
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        openURLContexts(URLContexts)
    }
    
    private func openURLContexts(_ URLContexts: Set<UIOpenURLContext>) {
        guard let appViewController else {
            return
        }
        
        guard let firstURL = URLContexts.first?.url else {
            return
        }
        
        guard let activity = NSUserActivity.wmf_activity(forWikipediaScheme: firstURL) ?? NSUserActivity.wmf_activity(for: firstURL) else {
            resumeAppIfNecessary()
            return
        }
        
        appViewController.showSplashView()
        _ = appViewController.processUserActivity(activity, animated: false) { [weak self] in
            
            guard let self else {
                return
            }
            
            if appNeedsResume {
                resumeAppIfNecessary()
            } else {
                appViewController.hideSplashView()
            }
        }
    }

    // MARK: Private
    
    private var appDelegate: AppDelegate? {
        return UIApplication.shared.delegate as? AppDelegate
    }
    
    private var appViewController: WMFAppViewController? {
        return appDelegate?.appViewController
    }
    
    private func resumeAppIfNecessary() {
        if appNeedsResume {
            appViewController?.hideSplashScreenAndResumeApp()
            appNeedsResume = false
        }
    }
    
#endif
}
