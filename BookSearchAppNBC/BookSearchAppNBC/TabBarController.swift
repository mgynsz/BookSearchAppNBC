//
//  TabBarController.swift
//  NBCBookStrore
//
//  Created by David Jang on 5/1/24.
//

import UIKit
import SnapKit

class TabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewControllers()
        setupTabBarAppearance()
    }
    
    private func setupViewControllers() {
        let searchVC = UINavigationController(rootViewController: SearchVC())
        let searchImage = UIImage(systemName: "magnifyingglass.circle.fill")?.withRenderingMode(.automatic)
        searchVC.tabBarItem = UITabBarItem(title: "", image: searchImage, selectedImage: searchImage)
        
        let addListVC = UINavigationController(rootViewController: AddListVC())
        let addListImage = UIImage(systemName: "list.bullet.circle.fill")?.withRenderingMode(.automatic)
        addListVC.tabBarItem = UITabBarItem(title: "", image: addListImage, selectedImage: addListImage)
        tabBar.backgroundColor = .white

        viewControllers = [searchVC, addListVC]
    }
    
    private func setupTabBarAppearance() {
        tabBar.barTintColor = .white
        tabBar.tintColor = .black
        tabBar.unselectedItemTintColor = .lightGray
    }
}
