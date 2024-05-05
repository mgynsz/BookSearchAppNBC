//
//  SceneDelegate.swift
//  BookSearchAppNBC
//
//  Created by David Jang on 5/5/24.
//

import UIKit
import SnapKit
import CoreData

class AddListVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // UI에 보여줄 책 목록 배열 생성
    var books: [Document] = []
    
    // 책 목록을 보여줄 테이블뷰 컴포넌트 선언
    private var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(named: "AccentColor")
        setupTableView()
        configureNavigationBar()
        loadBooks()
        
        // 책이 추가되면 알림을 받을 옵저버
        NotificationCenter.default.addObserver(self, selector: #selector(loadBooks), name: NSNotification.Name("BookAdded"), object: nil)
    }
    
    // 뷰컨 메모리 해제시 옵저버 해제
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: 뷰 셋업
    
    // 네비게이션 영역
    private func configureNavigationBar() {
        let deleteButton = UIBarButtonItem(title: "전체 삭제", style: .plain, target: self, action: #selector(deleteAllBooks))
        deleteButton.tintColor = .darkGray
        title = "ADD LIST"
        navigationItem.rightBarButtonItem = deleteButton
    }
    
    // 테이블뷰 설정
    private func setupTableView() {
        tableView = UITableView(frame: self.view.bounds, style: .plain)
        tableView.register(SearchResultTableViewCell.self, forCellReuseIdentifier: SearchResultTableViewCell.identifier)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 200
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor(named: "AccentColor")
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    var coreDataContext: NSManagedObjectContext? {
            return (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext
        }
    
    @objc func loadBooks() {
        guard let context = coreDataContext else { return }
        
        let fetchRequest: NSFetchRequest<SavedBook> = SavedBook.fetchRequest()
        do {
            let results = try context.fetch(fetchRequest)
            books = results.map { Document(from: $0) }
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        } catch {
            print("Error: \(error)")
        }
    }
    
    func deleteBook(at indexPath: IndexPath) {
        guard let context = coreDataContext else { return }
        
        let bookToDelete = books[indexPath.row]
        if let coreDataBook = fetchCoreDataBook(with: bookToDelete.title ?? "") {
            context.delete(coreDataBook)
            do {
                try context.save()
                books.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
            } catch let error as NSError {
                print("Error : \(error), \(error.userInfo)")
            }
        }
    }
    
    @objc func deleteAllBooks() {
        guard let context = coreDataContext else { return }
        
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = SavedBook.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try context.execute(deleteRequest)
            try context.save()
            books.removeAll()
            tableView.reloadData()
        } catch let error as NSError {
            print("전체 삭제: \(error), \(error.userInfo)")
        }
    }
    
    // title로 책 검색 데이터를
    func fetchCoreDataBook(with title: String) -> SavedBook? {
        guard let context = coreDataContext else { return nil }
        
        let fetchRequest: NSFetchRequest<SavedBook> = SavedBook.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "title == %@", title)
        
        do {
            let results = try context.fetch(fetchRequest)
            return results.first
        } catch {
            return nil
        }
    }
    
    // MARK: 테이븗뷰 셀 설정

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return books.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SearchResultTableViewCell.identifier, for: indexPath) as? SearchResultTableViewCell else {
            fatalError("셀 가져오기 실패")
        }
        let book = books[indexPath.row]
        cell.configure(with: book)
        cell.contentView.backgroundColor = UIColor(named: "AccentColor")
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            deleteBook(at: indexPath)
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "목록"
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 160
    }
}
