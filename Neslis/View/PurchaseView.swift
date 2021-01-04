//
//  PurchaseView.swift
//  Neslis
//
//  Created by Sergey Volkov on 23.08.2020.
//  Copyright © 2020 Sergei Volkov. All rights reserved.
//

import SwiftUI


struct PurchaseView: View {
    
    @ObservedObject var userAlert = UserAlert.shared
    @ObservedObject var progressData = ProgressData.shared
    
    @State var showTerms = false
    
    @Environment(\.managedObjectContext) private var viewContext
    fileprivate func processing() {
        progressData.activitySpinnerAnimate = true
        progressData.activitySpinnerText = TxtLocal.Alert.Text.processing
        progressData.showProgressBar = false
    }
    
    var body: some View {
        
        LoadingView(isShowing: $progressData.activitySpinnerAnimate, text: progressData.activitySpinnerText, progressBar: $progressData.value, showProgressBar: $progressData.showProgressBar, content: {
            
            VStack(alignment: .center, spacing: 14) {
                Spacer()
                Text(TxtLocal.Text.upgradeToPro)
                    .font(Font.system(size: 24, weight: .bold, design: .default))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(TxtLocal.Text.dataBackup)
                            .foregroundColor(.white)
                            .lineLimit(nil)
                            .multilineTextAlignment(.leading)
                    }
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(TxtLocal.Text.sharingLists)
                            .foregroundColor(.white)
                            .lineLimit(nil)
                            .multilineTextAlignment(.leading)
                    }
                }
                
                Button(action: {
                    processing()
                    IAPManager.shared.purshase(product: IAPManager.shared.products[0])
                }) {
                    HStack {
                        Text(TxtLocal.contentBody.oneMonth)
                        Spacer()
                        Text("\(IAPManager.shared.priceOfProduct(product: IAPManager.shared.products[0]))")
                    }
                    .padding(.horizontal)
                }
                .modifier(PurchaseButtonModifire())
                .frame(height: 50)
                
                Button(action: {
                    processing()
                    IAPManager.shared.purshase(product: IAPManager.shared.products[1])
                }) {
                    VStack {
                        HStack {
                            Text(TxtLocal.contentBody.oneYear)
                            Spacer()
                            Text("\(IAPManager.shared.priceOfProduct(product: IAPManager.shared.products[1]))")
                        }
                        .padding(.horizontal)
                        
//                        HStack {
//                            Text("\(TxtLocal.Text.yourSave)")
//                            Text("\(Int(round(100 - Double(truncating: IAPManager.shared.products[1].price) / (Double(truncating: IAPManager.shared.products[0].price) * 12) * 100)))%")
//
//                        }
//                        .padding(.horizontal)
//                        .font(Font.system(size: 14, weight: .thin, design: .default))
                    }
                }
                .modifier(PurchaseButtonModifire())
                
                Button(TxtLocal.Button.restorePurchases) {
                    IAPManager.shared.restoreCompletedTransaction()
                }
                .foregroundColor(.red)
                ScrollView {
                    Text(TxtLocal.Text.recurringBilling)
                        .font(.system(size: 12, weight: .thin, design: .default))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Button(TxtLocal.contentBody.termsConditions) {
                    showTerms = true
                }
                .frame(maxHeight: 10)
                .fixedSize(horizontal: false, vertical: true)
                .font(.system(size: 12))
                .padding(.bottom)
            }
            .padding()
            .background(ZStack{
                Image("NeslisLaunchScreen")
                    .blur(radius: (1 - 0.6) * 20)
                    .scaledToFill()
                Color.black.opacity(0.7)
            })
        })
        .alert(item: $userAlert.alertType) { alert in
            switch alert {
            case .networkError:
                return Alert(
                    title: Text(TxtLocal.Alert.Title.error),
                    message: Text(userAlert.text),
                    dismissButton: .cancel(Text(TxtLocal.Button.ok))
                )
            case .noAccessToNotification:
                return Alert(
                    title: Text(userAlert.title),
                    message: Text(userAlert.text),
                    dismissButton: .cancel(Text(TxtLocal.Button.ok))
                )
            default:
                return Alert(title: Text(""))
            }
        }
        .sheet(isPresented: $showTerms) {
            TermsConditions()
        }
        .onAppear() {
            DispatchQueue.main.async {
                IAPManager.shared.getProducts()
            }
        }
        
        
        
    }
}
