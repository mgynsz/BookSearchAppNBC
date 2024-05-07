//
//  DetailVC.swift
//  NBCBookStrore
//
//  Created by David Jang on 5/2/24.
//

import UIKit
import SnapKit
import SDWebImage
import CoreData

class DetailVC: UIViewController {
    
    // 모델 뷰 상단 닫기 표시
    private let dragIndicatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.darkGray
        view.layer.cornerRadius = 3
        return view
    }()
    
    // 책 제목
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    // 작가
    private let authorLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .darkGray
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    // 책 이미지
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 4
        imageView.clipsToBounds = true
        return imageView
    }()
    
    // 책 설명
    private let descriptionTextView: UITextView = {
        let textView = UITextView()
        textView.isEditable = false
        textView.isScrollEnabled = true
        textView.backgroundColor = UIColor(named: "AccentColor")
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 7
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14),
            .paragraphStyle: paragraphStyle
        ]
        
        textView.attributedText = NSAttributedString(string: "여기에 텍스트 입력", attributes: attributes)
        
        return textView
    }()
    
    // 담기 버튼
    private let addButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("담기", for: .normal)
        button.backgroundColor = UIColor.systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        return button
    }()
    
    var book: Document?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        configureView()
        view.backgroundColor = UIColor(named: "AccentColor")
        
        addButton.addTarget(self, action: #selector(addBookToList), for: .touchUpInside)
    }
    
    // UI 레이아웃
    private func setupViews() {
        view.addSubview(titleLabel)
        view.addSubview(authorLabel)
        view.addSubview(imageView)
        view.addSubview(descriptionTextView)
        view.addSubview(dragIndicatorView)
        view.addSubview(addButton)
        
        dragIndicatorView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(8)
            make.centerX.equalTo(view)
            make.width.equalTo(72)
            make.height.equalTo(6)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(24)
            make.left.right.equalTo(view).inset(16)
        }
        
        authorLabel.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.top).offset(8)
            make.leading.equalTo(imageView.snp.trailing).offset(16)
        }
        
        imageView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(32)
            make.left.equalTo(view).inset(16)
            make.height.equalTo(240)
            make.width.equalTo(160)
        }
        
        descriptionTextView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.left.right.bottom.equalTo(view).inset(16)
        }
        
        addButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(20)
            make.height.equalTo(50)
            make.width.equalTo(100)
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
    
    private func configureView() {
        guard let book = book else { return }
        print("Configuring DetailVC with book: \(book)")
        titleLabel.text = book.title
        authorLabel.text = book.authors?.joined(separator: ", ")
        descriptionTextView.text = book.contents
        // 가격 정보 설정 확인
        if let price = book.price {
            print("Price: \(price)")  // 콘솔에 가격 정보 출력
        }
        
        if let url = URL(string: book.thumbnail ?? "") {
            imageView.sd_setImage(with: url, placeholderImage: UIImage(named: "placeholderImage"))
        }
    }
    
    // CoreData 컨텍스트 가져오기
    var coreDataContext: NSManagedObjectContext? {
        return (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext
    }
    
    // 책 coredata에 저장 메서드
    @objc func addBookToList() {
        guard let context = coreDataContext else { return }
        
        let fetchRequest: NSFetchRequest<SavedBook> = SavedBook.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "title == %@", book?.title ?? "")
        
        do {
            let results = try context.fetch(fetchRequest)
            if results.isEmpty {
                let newBook = SavedBook(context: context)
                newBook.title = book?.title
                newBook.authors = book?.authors?.joined(separator: ", ")
                newBook.thumbnailUrl = book?.thumbnail
                newBook.price = Int16(book?.price ?? 0)
                try context.save()
                NotificationCenter.default.post(name: NSNotification.Name("BookAdded"), object: nil)
                dismiss(animated: true, completion: nil)
            } else {
                showAlert(title: "중복 책", message: "이 책은 이미 리스트에 있습니다.")
            }
        } catch {
            print("Error addBookToList: \(error)")
        }
    }
    
    // title로 coredata에서 책 찾기
    func fetchCoreDataBook(with title: String, context: NSManagedObjectContext) -> SavedBook? {
        let fetchRequest: NSFetchRequest<SavedBook> = SavedBook.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "title == %@", title)
        
        do {
            let results = try context.fetch(fetchRequest)
            return results.first
        } catch {
            return nil
        }
    }
}

