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
    
    private let dragIndicatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.darkGray
        view.layer.cornerRadius = 3
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private let authorLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .darkGray
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 4
        imageView.clipsToBounds = true
        return imageView
    }()
    
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
    
    @objc func addBookToList() {
        guard let context = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext, let title = book?.title else {
            return
        }
        
        let fetchRequest: NSFetchRequest<SavedBook> = SavedBook.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "title == %@", title)
        
        do {
            let results = try context.fetch(fetchRequest)
            if results.isEmpty {
                let newBook = SavedBook(context: context)
                newBook.title = title
                newBook.authors = book?.authors?.joined(separator: ", ") ?? "작가 정보 없음"
                newBook.thumbnailUrl = book?.thumbnail ?? ""
                newBook.price = Int16(book?.price ?? 0) // 가격 정보 저장
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
    
    func fetchCoreDataBook(with title: String) -> SavedBook? {
        guard let context = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext else {
            return nil
        }
        
        let fetchRequest: NSFetchRequest<SavedBook> = SavedBook.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "title == %@", title)
        
        do {
            let results = try context.fetch(fetchRequest)
            return results.first
        } catch {
            return nil
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
    
    
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
    
    private func configureView() {
        guard let book = book else { return }
        
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
}

