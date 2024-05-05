//
//  ViewController.swift
//  NBCBookStrore
//
//  Created by David Jang on 5/1/24.
//

import UIKit
import SnapKit
import CoreData

class SearchVC: UIViewController, UINavigationControllerDelegate, UISearchBarDelegate {
    
    lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search.."
        searchBar.layer.borderColor = UIColor.black.cgColor
        searchBar.layer.borderWidth = 1
        searchBar.layer.cornerRadius = 8
        customizeSearchBarTextField(searchBar)
        return searchBar
    }()
    
    private var books: [Document] = []
    private var recentBooks: [Document] = []
    var searchBarHeightConstraint: Constraint?
    private var collectionView: UICollectionView!
    private var tableView: UITableView!
    private var currentPage = 1 // 페이지 번호 관리
    private var isLastPage = false // 마지막 페이지인지 여부
    private var isLoadingMoreBooks = false // 추가 데이터 로딩 중인지 상태
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        setupView()
        setupTableView()
        setupKeyboardDismissTapGesture()
        searchBar.delegate = self
        loadInitialData()
        fetchRecentBooks()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        configureLayout()
    }
    
    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 80, height: 120)
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.clipsToBounds = false
        collectionView.register(RecentlyCollectionViewCell.self, forCellWithReuseIdentifier: RecentlyCollectionViewCell.identifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        view.addSubview(collectionView)
    }
    
    private func setupTableView() {
        tableView = UITableView(frame: self.view.bounds, style: .plain)
        tableView.register(SearchResultTableViewCell.self, forCellReuseIdentifier: SearchResultTableViewCell.identifier)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 200
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor(named: "AccentColor")
        view.addSubview(tableView)
    }
    
    private func setupView() {
        view.backgroundColor = UIColor(named: "AccentColor")
        
        view.addSubview(searchBar)
        
        title = "BOOK"
    }
    
    private func configureLayout() {
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(16)
            make.left.right.equalTo(view).offset(16)
            make.trailing.equalTo(view.safeAreaLayoutGuide.snp.trailing).offset(-16)
            make.height.equalTo(140)
        }
        
        searchBar.snp.makeConstraints { make in
            make.top.equalTo(collectionView.snp.bottom).offset(16)
            make.left.right.equalTo(view).inset(16)
            searchBarHeightConstraint = make.height.equalTo(60).constraint
        }
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(searchBar.snp.bottom).offset(8)
            make.left.right.equalTo(view)
            if let tabBar = tabBarController?.tabBar {
                make.bottom.equalTo(tabBar.snp.top)
            } else {
                make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
            }
        }
    }
    
    func loadInitialData() {
        let initialQuery = "기본 검색어"  // 예: "베스트셀러"
        if !initialQuery.isEmpty {
            currentPage = 1
            isLastPage = false
            loadBooks(query: initialQuery)
        }
    }
    
    func loadBooks(query: String) {
        guard !isLoadingMoreBooks && !isLastPage else { return } // 중복 로딩 방지 및 마지막 페이지 체크
        isLoadingMoreBooks = true
        
        Task {
            do {
                let response = try await BookManager.shared.fetchBooks(query: query, page: currentPage)
                if currentPage == 1 {
                    self.books = response.documents
                } else {
                    self.books.append(contentsOf: response.documents)
                }
                isLastPage = response.meta.isEnd
                currentPage += 1
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
                isLoadingMoreBooks = false
            } catch {
                print("Error loading books: \(error)")
                isLoadingMoreBooks = false
            }
        }
    }
    
    func loadMoreBooks() {
        guard !isLoadingMoreBooks && !isLastPage else { return }
        currentPage += 1  // 다음 페이지로 이동
        loadBooks(query: searchBar.text ?? "")  // 책 로드 함수 호출
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let searchText = searchBar.text, !searchText.isEmpty else {
            searchBar.resignFirstResponder()
            return
        }
        currentPage = 1
        isLastPage = false
        loadBooks(query: searchText)
        searchBar.resignFirstResponder() // 키보드 내리기
    }
    
    func fetchRecentBooks() {
        guard let context = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext else {
            return
        }

        let fetchRequest: NSFetchRequest<RecentBook> = RecentBook.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "dateAdded", ascending: false)]
        fetchRequest.fetchLimit = 20

        do {
            let results = try context.fetch(fetchRequest)
            recentBooks = results.map { Document(from: $0) }
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        } catch {
            print("Failed fetchRecentBooks: \(error)")
        }
    }

    func updateRecentBooks(with book: Document) {
        guard let context = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext else {
            return
        }

        let fetchRequest: NSFetchRequest<RecentBook> = RecentBook.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "title == %@", book.title ?? "")

        do {
            let results = try context.fetch(fetchRequest)
            if let existingBook = results.first {
                existingBook.dateAdded = Date() // 이미 존재하면 최신 날짜로 업데이트
            } else {
                let newRecentBook = RecentBook(context: context)
                newRecentBook.title = book.title
                newRecentBook.authors = book.authors?.joined(separator: ", ")
                newRecentBook.thumbnailUrl = book.thumbnail
                newRecentBook.dateAdded = Date()
            }
            try context.save()
            fetchRecentBooks() // 최근 본 책 목록 갱신
        } catch {
            print("Failed updateRecentBooks: \(error)")
        }
    }

    func saveRecentBook(_ book: Document) {
        guard let context = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext else {
            return
        }
        
        let newRecentBook = RecentBook(context: context)
        newRecentBook.title = book.title
        newRecentBook.authors = book.authors?.joined(separator: ", ")
        newRecentBook.thumbnailUrl = book.thumbnail
        newRecentBook.dateAdded = Date()

        do {
            try context.save()
            fetchRecentBooks() // 저장 후 최근 본 책 목록 갱신
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    private func setupKeyboardDismissTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func presentDetailViewController(for book: Document) {
        let detailVC = DetailVC()
        detailVC.book = book
        detailVC.modalPresentationStyle = .formSheet
        present(detailVC, animated: true)
    }
    
    func customizeSearchBarTextField(_ searchBar: UISearchBar) {
        if let textField = searchBar.value(forKey: "searchField") as? UITextField {
            textField.backgroundColor = .white
            textField.layer.cornerRadius = 8
            textField.clipsToBounds = true
            textField.font = UIFont.systemFont(ofSize: 16)
            textField.textColor = .black
            textField.attributedPlaceholder = NSAttributedString(string: textField.placeholder ?? "", attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray])
        }
    }
}

extension SearchVC: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return recentBooks.count
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // 선택된 책 가져오기
        let selectedBook = recentBooks[indexPath.row]
        // 상세 페이지로 이동
        presentDetailViewController(for: selectedBook)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RecentlyCollectionViewCell", for: indexPath) as? RecentlyCollectionViewCell else {
            fatalError("Unable to dequeue RecentlyCollectionViewCell")
        }
        let book = recentBooks[indexPath.row]
        if let thumbnailUrl = book.thumbnail, let url = URL(string: thumbnailUrl) {
            cell.imageView.sd_setImage(with: url, placeholderImage: UIImage(named: "placeholder"))
        }
        return cell
    }
}

extension SearchVC: UITableViewDataSource, UITableViewDelegate {

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

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedBook = books[indexPath.row]
        updateRecentBooks(with: selectedBook)
        presentDetailViewController(for: selectedBook)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // 마지막 셀에 도달했을 때 추가 데이터 로드
        if indexPath.row == books.count - 1 && !isLastPage && !isLoadingMoreBooks {
            loadMoreBooks()
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "검색 결과"
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 160
    }
}
