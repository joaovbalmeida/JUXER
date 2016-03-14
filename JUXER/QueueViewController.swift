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
        juxerButton.hidden = false
        juxerLabel.hidden = false
    }
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var juxerButton: UIButton!
    @IBOutlet weak var juxerLabel: UILabel!

    

    private let kHeaderHeight: CGFloat = 300
    let darkBlur = UIBlurEffect(style: UIBlurEffectStyle.Dark)
    var headerView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        headerView = tableView.tableHeaderView
        headerView.clipsToBounds = true
        
        tableView.tableHeaderView = nil
        tableView.addSubview(headerView)
        
        tableView.contentInset = UIEdgeInsets(top: kHeaderHeight, left: 0, bottom: 0, right: 0)
        tableView.contentOffset = CGPoint(x: 0, y: -kHeaderHeight)

        tableView.allowsSelection = false
    }
    
    override func viewDidDisappear(animated: Bool) {
        juxerLabel.hidden = true
        juxerButton.hidden = true
    }
    
    override func viewDidAppear(animated: Bool) {
        juxerButton.hidden = false
        juxerLabel.hidden = false
        updateHeaderView()
    }
    
    func updateHeaderView() {
        var buttonRect = CGRect(x: view.bounds.midX - 76, y: -tableView.contentOffset.y - 15, width: 152, height: 35)
        var headerRect = CGRect(x: 0, y: -kHeaderHeight, width: view.bounds.width , height: kHeaderHeight)
        if tableView.contentOffset.y <= -120 {
            headerRect.size.height = -tableView.contentOffset.y
            headerRect.origin.y = tableView.contentOffset.y
            buttonRect.origin.y = -tableView.contentOffset.y - 15
        } else if tableView.contentOffset.y > -120 {
            headerRect.size.height = 120
            headerRect.origin.y = tableView.contentOffset.y
            buttonRect.origin.y = 105
        }
        juxerLabel.frame = buttonRect
        juxerButton.frame = buttonRect
        headerView.frame = headerRect
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch (section) {
        case 0:
            return 1
        case 1:
            return 30
        default:
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch (indexPath.section) {
        case 0:
            let cell = tableView.dequeueReusableCellWithIdentifier("header", forIndexPath: indexPath)
            cell.separatorInset = UIEdgeInsetsZero
            cell.layoutMargins = UIEdgeInsetsZero
            return cell
        case 1:
            let cell = tableView.dequeueReusableCellWithIdentifier("queue", forIndexPath: indexPath)
            cell.separatorInset = UIEdgeInsetsZero
            cell.layoutMargins = UIEdgeInsetsZero
            return cell
        default:
            let cell = tableView.dequeueReusableCellWithIdentifier("header", forIndexPath: indexPath)
            return cell
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch (indexPath.section) {
        case 0:
            return 40
        case 1:
            return 70
        default:
            return 0
        }
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        updateHeaderView()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
