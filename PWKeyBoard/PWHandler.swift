//
//  PWHandler.swift
//  VehicleKeyboardDemo
//
//  Created by 杨志豪 on 2018/6/28.
//  Copyright © 2018年 yangzhihao. All rights reserved.
//

import UIKit

@objc protocol PWHandlerDelegate{
    @objc  func plateInputComplete(plate: String)
    @objc optional func palteDidChnage(plate:String,complete:Bool)
    @objc optional func plateKeyBoardShow()
    @objc optional func plateKeyBoardHidden()
}

class PWHandler: NSObject,UICollectionViewDelegate,UICollectionViewDelegateFlowLayout,UICollectionViewDataSource,PWKeyBoardViewDeleagte {
    
    let identifier = "PWInputCollectionViewCell"
    var inputCollectionView :UICollectionView!
    var maxCount = 7
    var selectIndex = 0
    var inputTextfield :UITextField!
    let keyboardView = PWKeyBoardView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
    var paletNumber = ""
    var selectView = UIView()
    var collectionViewResponder = false
    
    weak var  delegate : PWHandlerDelegate?
    
    func setKeyBoardView(collectionView:UICollectionView){
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UINib(nibName: identifier, bundle: nil), forCellWithReuseIdentifier: identifier)
        inputCollectionView = collectionView
        inputTextfield = UITextField(frame: CGRect.zero)
        collectionView.addSubview(inputTextfield)
        keyboardView.delegate = self
        inputTextfield.inputView = keyboardView
        
        //因为直接切给collectionView加边框 会盖住蓝色的选中边框   所以加一个和collectionView一样大的view再切边框
        let backgroundView = UIView(frame: collectionView.bounds)
        collectionView.backgroundView = backgroundView
        backgroundView.layer.borderWidth = 1
        backgroundView.layer.borderColor = UIColor(red: 216/255.0, green: 216/255.0, blue: 216/255.0, alpha: 1).cgColor
        backgroundView.isUserInteractionEnabled = false
        backgroundView.layer.masksToBounds = true
        backgroundView.layer.cornerRadius = 2
        selectView.isUserInteractionEnabled = false
        collectionView.addSubview(selectView)
        
        //监听键盘
        NotificationCenter.default.addObserver(self, selector: #selector(plateKeyBoardShow), name:NSNotification.Name.UIKeyboardDidShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(plateKeyBoardHidden), name:NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    @objc func plateKeyBoardShow(){
        if inputTextfield.isFirstResponder , !collectionViewResponder {
            delegate?.plateKeyBoardShow?()
        }
    }
    
    @objc func plateKeyBoardHidden(){
        if inputTextfield.isFirstResponder , !collectionViewResponder{
            delegate?.plateKeyBoardHidden?()
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectIndex = indexPath.row > paletNumber.count ? paletNumber.count : indexPath.row
        keyboardView.updateText(text: paletNumber, isMoreType: false, inputIndex: selectIndex)
        updateCollection()
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return maxCount
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize(width: (collectionView.bounds.size.width / CGFloat(maxCount)), height: collectionView.bounds.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! PWInputCollectionViewCell
        cell.charLabel.text = getPaletChar(index: indexPath.row)
        if indexPath.row == selectIndex {
            //给cell加上选中的边框
            selectView.layer.borderWidth = 2
            selectView.layer.borderColor = UIColor.blue.cgColor
            selectView.frame = cell.frame
            corners(view: selectView, index: selectIndex)
        }
        corners(view: cell, index: indexPath.row)
        cell.layer.masksToBounds = true
        return cell
    }
    
    
    func updateCollection(){
        collectionViewResponder = true
        inputCollectionView.reloadData()
        if !inputTextfield.isFirstResponder {
            inputTextfield.becomeFirstResponder()
        }
        collectionViewResponder = false
    }
    
    func selectComplete(char: String, inputIndex: Int) {
        
        var isMoreType = false
        if char == "删除" , paletNumber.count >= 1 {
            paletNumber = Engine.subString(str: paletNumber, start: 0, length: paletNumber.count - 1)
            selectIndex = paletNumber.count
        }else  if char == "确定"{
            UIApplication.shared.keyWindow?.endEditing(true)
            delegate?.plateInputComplete(plate: paletNumber)
            return
        }else if char == "更多" {
            isMoreType = true
        } else if char == "返回" {
            isMoreType = false
        } else {
            if paletNumber.count <= inputIndex{
                paletNumber += char
            } else {
                let NSPalet = NSMutableString(string: paletNumber)
                NSPalet.replaceCharacters(in: NSRange(location: inputIndex, length: 1), with: char)
                paletNumber = NSString.init(format: "%@", NSPalet) as String
            }
            let keyboardView = inputTextfield.inputView as! PWKeyBoardView
            let numType = keyboardView.numType == .newEnergy ? PWKeyboardNumType.newEnergy : Engine.detectNumberTypeOf(presetNumber: paletNumber)
            maxCount = (numType == .newEnergy || numType == .wuJing) ? 8 : 7
            if maxCount > paletNumber.count || selectIndex < paletNumber.count - 1 {
                selectIndex += 1;
            }
        }
        delegate?.palteDidChnage?(plate:paletNumber,complete:paletNumber.count == maxCount)
        keyboardView.updateText(text: paletNumber, isMoreType: isMoreType, inputIndex: selectIndex)
        updateCollection()
    }
    
    func setPlate(plate:String,type:PWKeyboardNumType){
        paletNumber = plate;
        let isNewEnergy = type == .newEnergy
        var numType = type;
        if  numType == .auto,paletNumber.count > 0,Engine.subString(str: paletNumber, start: 0, length: 1) == "W" {
            numType = .wuJing
        } else if numType == .auto,paletNumber.count == 8 {
            numType = .newEnergy
        }
        keyboardView.numType = numType
        changeInputType(isNewEnergy: isNewEnergy)
    }
    
    func getPaletChar(index:Int) -> String{
        if paletNumber.count > index {
            let NSPalet = paletNumber as NSString
            let char = NSPalet.substring(with: NSRange(location: index, length: 1))
            return char
        }
        return ""
    }
    
    func changeInputType(isNewEnergy:Bool){
        let keyboardView = inputTextfield.inputView as! PWKeyBoardView
        keyboardView.numType = isNewEnergy ? .newEnergy : .auto
        var numType = keyboardView.numType
        if  paletNumber.count > 0,Engine.subString(str: paletNumber, start: 0, length: 1) == "W" {
            numType = .wuJing
        }
        maxCount = (numType == .newEnergy || numType == .wuJing) ? 8 : 7
        if paletNumber.count > maxCount {
            paletNumber = Engine.subString(str: paletNumber, start: 0, length: paletNumber.count - 1)
        } else if maxCount == 8,paletNumber.count == 7 {
            selectIndex = 7
        }
        if selectIndex > (maxCount - 1) {
            selectIndex = maxCount - 1
        }
        keyboardView.updateText(text: paletNumber, isMoreType: false, inputIndex: selectIndex)
        updateCollection()
    }
    
    func corners(view:UIView, index :Int){
        view.addRounded(cornevrs: UIRectCorner.allCorners, radii: CGSize(width: 0, height: 0))
        if index == 0{
            view.addRounded(cornevrs: UIRectCorner(rawValue: UIRectCorner.RawValue(UInt8(UIRectCorner.topLeft.rawValue) | UInt8(UIRectCorner.bottomLeft.rawValue))), radii: CGSize(width: 2, height: 2))
        } else if index == maxCount - 1 {
            view.addRounded(cornevrs: UIRectCorner(rawValue: UIRectCorner.RawValue(UInt8(UIRectCorner.topRight.rawValue) | UInt8(UIRectCorner.bottomRight.rawValue))), radii: CGSize(width: 2, height: 2))
        }
    }
    
}