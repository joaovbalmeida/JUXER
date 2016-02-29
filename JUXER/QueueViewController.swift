//
//  QueueViewController.swift
//  JUXER
//
//  Created by Joao Victor Almeida on 25/02/16.
//  Copyright © 2016 Joao Victor Almeida. All rights reserved.
//

import UIKit

class QueueViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBAction func unwindToVC(segue: UIStoryboardSegue) {
    }
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var juxerButton: UIButton!
    
    var headerView: UIView!
    private let kHeaderHeight: CGFloat = 250
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor(patternImage: UIImage(named: "HomeBackground.png")!)
        
        headerView = tableView.tableHeaderView
        headerView.clipsToBounds = true
        tableView.tableHeaderView = nil
        tableView.addSubview(headerView)
        tableView.contentInset = UIEdgeInsets(top: kHeaderHeight, left: 0, bottom: 0, right: 0)
        tableView.contentOffset = CGPoint(x: 0, y: -kHeaderHeight)

        tableView.allowsSelection = false
        
    }
    
    override func viewWillAppear(animated: Bool) {
        updateHeaderView()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func updateHeaderView() {
        var headerRect = CGRect(x: 0, y: -kHeaderHeight, width: tableView.bounds.width, height: kHeaderHeight)
        var buttonRect = CGRect(x: view.bounds.midX - 76, y: -235, width: 152, height: 35)
        if tableView.contentOffset.y <= -120 {
            headerRect.size.height = -tableView.contentOffset.y
            headerRect.origin.y = tableView.contentOffset.y
            buttonRect.origin.y = -tableView.contentOffset.y - 15
        } else if tableView.contentOffset.y > -120 {
            headerRect.size.height = 120
            headerRect.origin.y = tableView.contentOffset.y
            buttonRect.origin.y = 105
        }
        juxerButton.frame = buttonRect
        headerView.frame = headerRect
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return 30
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("queue", forIndexPath: indexPath)
        tableView.rowHeight = 70
        cell.separatorInset = UIEdgeInsetsZero
        cell.layoutMargins = UIEdgeInsetsZero
        return cell
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        updateHeaderView()
    }
}
