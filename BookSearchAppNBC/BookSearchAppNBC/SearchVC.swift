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
    
    // 서치바 lazy 선언으로 사용 전 까지는 메모리 할당 안됨
    lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search.."
        searchBar.layer.borderColor = UIColor.black.cgColor
        searchBar.layer.borderWidth = 1
        searchBar.layer.cornerRadius = 8
        customizeSearchBarTextField(searchBar)
        return searchBar
    }()
    
    private var books: [Document] = []         // 검색 결과를 보관 배열
    private var recentBooks: [Document] = []    // 최근 본 책을 보관하는 배열
    var searchBarHeightConstraint: Constraint?   // 서치바 제약 설정 변경 변수
    private var collectionView: UICollectionView! // 컬렉션뷰 컴포넌트 선언
    private var tableView: UITableView!         // 테이블뷰 컴포넌트 선언
    private var currentPage = 1             // 페이지 번호 관리
    private var isLastPage = false          // 마지막 페이지인지 여부
    private var isLoadingMoreBooks = false   // 추가 데이터 로딩 중인지 상태
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        setupView()
        setupTableView()
        setupKeyboardDismissTapGesture()
        loadInitialData()
        fetchRecentBooks()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        configureLayout()
    }
    
    // MARK: 뷰 셋업
    
    // 컬렉션뷰 설정
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
    }
    
    // 기타 UI 설정
    private func setupView() {
        view.backgroundColor = UIColor(named: "AccentColor")
        searchBar.delegate = self
        view.addSubview(searchBar)
        title = "BOOK"
    }
    
    // 서치바 설정
    private func customizeSearchBarTextField(_ searchBar: UISearchBar) {
        if let textField = searchBar.value(forKey: "searchField") as? UITextField {
            textField.backgroundColor = .white
            textField.layer.cornerRadius = 8
            textField.clipsToBounds = true
            textField.font = UIFont.systemFont(ofSize: 16)
            textField.textColor = .black
            textField.attributedPlaceholder = NSAttributedString(string: textField.placeholder ?? "", attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray])
        }
    }
    
    // UI 레이아웃
    private func configureLayout() {
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(16)
            make.left.right.equalTo(view).offset(16)
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
    
    // 키보드 내리기 제스처
    private func setupKeyboardDismissTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: 화면 이동
    
    private func presentDetailViewController(for book: Document) {
        let detailVC = DetailVC()    // 인스턴스 생성
        detailVC.book = book        // 객체 전달
        detailVC.modalPresentationStyle = .formSheet
        present(detailVC, animated: true)   // 모달
    }
    
    // MARK: 책 관리
    
    // CoreData 컨텍스트 가져오기
    var coreDataContext: NSManagedObjectContext? {
        return (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext
    }
    
    // 초기 데이터 로드
    func loadInitialData() {
        let initialQuery = "유시민"
        if !initialQuery.isEmpty {
            currentPage = 1
            isLastPage = false
            loadBooks(query: initialQuery)
        }
    }
    
    // 쿼리대로 책 로드
    func loadBooks(query: String) {
        guard !isLoadingMoreBooks && !isLastPage else { return } // 중복 로딩 방지 및 마지막 페이지 체크
        isLoadingMoreBooks = true
        
        Task {
            do {
                // 비동기적으로 가져오기
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
                isLoadingMoreBooks = false
            }
        }
    }
    
    // 스크롤로 추가 책 로드하면 실행
    func loadMoreBooks() {
        guard !isLoadingMoreBooks && !isLastPage else { return } // 중복 로딩 방지 및 마지막 페이지 체크
        currentPage += 1  // 다음 페이지로 이동
        loadBooks(query: searchBar.text ?? "")  // 책 로드 함수 호출
    }
    
    // 키보드 검색누르면 실행
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
    
    // 최근 본 책
    func fetchRecentBooks() {
        guard let context = coreDataContext else { return }
        
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
            
        }
    }
    
    // 최근 본 책을 업데이트하고 새로 저장하는 메서드
    func updateOrSaveRecentBook(_ book: Document) {
        guard let context = coreDataContext else { return }
        
        let fetchRequest: NSFetchRequest<RecentBook> = RecentBook.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "title == %@", book.title ?? "")
        
        context.perform { [weak self] in
            do {
                let results = try context.fetch(fetchRequest)
                let recentBook = results.first ?? RecentBook(context: context)
                
                // 존재하면 업데이트, 존재하지 않으면 새로운 객체 설정
                recentBook.title = book.title
                recentBook.authors = book.authors?.joined(separator: ", ")
                recentBook.thumbnailUrl = book.thumbnail
                recentBook.dateAdded = Date()
                
                try context.save()
                self?.fetchRecentBooks() // 최근 본 책 목록 갱신
            } catch {
                
            }
        }
    }
    
    // API로 책 정보 불러오기
    func fetchDetailedBookData(for book: Document) {
        guard let query = book.title else { return }
        
        Task {
            do {
                let response = try await BookManager.shared.fetchBooks(query: query, page: 1, size: 1)
                if let detailedBook = response.documents.first {
                    DispatchQueue.main.async {
                        self.presentDetailViewController(for: detailedBook)
                    }
                }
            } catch {
                
            }
        }
    }
}

// MARK: 컬렉션뷰 설정

extension SearchVC: UICollectionViewDataSource, UICollectionViewDelegate {
    
    // 셀 갯수
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return recentBooks.count
    }
    
    // 셀 선택 시 로직
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // 선택된 책 가져오기
        let selectedBook = recentBooks[indexPath.row]
        fetchDetailedBookData(for: selectedBook)
    }
    
    // 셀 구성
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RecentlyCollectionViewCell", for: indexPath) as? RecentlyCollectionViewCell else {
            fatalError("셀 가져오기 실패")
        }
        let book = recentBooks[indexPath.row]
        if let thumbnailUrl = book.thumbnail, let url = URL(string: thumbnailUrl) {
            cell.imageView.sd_setImage(with: url, placeholderImage: UIImage(named: "placeholder"))
        }
        return cell
    }
}

// MARK: 테이블뷰 설정

extension SearchVC: UITableViewDataSource, UITableViewDelegate {
    
    // 셀 갯수
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return books.count
    }
    
    // 셀 구성
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SearchResultTableViewCell.identifier, for: indexPath) as? SearchResultTableViewCell else {
            fatalError("셀 가져오기 실패")
        }
        let book = books[indexPath.row]
        cell.configure(with: book)
        cell.contentView.backgroundColor = UIColor(named: "AccentColor")
        return cell
    }
    
    // 셀 선택 시 로직
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedBook = books[indexPath.row]
        updateOrSaveRecentBook(selectedBook)
        presentDetailViewController(for: selectedBook)
    }
    
    // 마지막 셀에 도달했을 때 추가 데이터 로드
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == books.count - 1 && !isLastPage && !isLoadingMoreBooks {
            loadMoreBooks()
        }
    }
    
    // 테이블뷰 섹션 헤더
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "검색 결과"
    }
    
    // 테이블뷰 셀 높이
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 160
    }
}
