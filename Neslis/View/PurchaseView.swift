//
//  PurchaseView.swift
//  Neslis
//
//  Created by Sergey Volkov on 23.08.2020.
//  Copyright © 2020 Sergei Volkov. All rights reserved.
//

import SwiftUI


struct PurchaseView: View {
    
    //@EnvironmentObject var loading: Loadspinner
    @Environment(\.managedObjectContext) private var viewContext
    var body: some View {
        
        VStack(alignment: .center, spacing: 14) {
            Text(TxtLocal.Text.upgradeToPro)
                .font(Font.system(size: 24, weight: .bold, design: .default))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
            
            VStack {
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
                IAPManager.shared.purshase(product: IAPManager.shared.products[0])
            }) {
                Text("\(IAPManager.shared.priceOfProduct(product: IAPManager.shared.products[0])) \(TxtLocal.Text.inMonth)")
                    .multilineTextAlignment(.center)
                    .font(.title3)
                    .padding()
                
            }
            .modifier(PurchaseButtonModifire())
            .frame(height: 50)
            
            Button(action: {
                IAPManager.shared.purshase(product: IAPManager.shared.products[1])
            }) {
                VStack{
                    Text("\(IAPManager.shared.priceOfProduct(product: IAPManager.shared.products[1])) \(TxtLocal.Text.inYear)")
                        .multilineTextAlignment(.center)
                        .font(.title3)
                    Text("\(TxtLocal.Text.yourSave) \(Int(round(100 - Double(truncating: IAPManager.shared.products[1].price) / (Double(truncating: IAPManager.shared.products[0].price) * 12) * 100)))%")
                        .font(Font.system(size: 22, weight: .bold, design: .default))
                }
            }
            .modifier(PurchaseButtonModifire())
            Text(TxtLocal.Text.recurringBilling)
                .font(.system(size: 12, weight: .thin, design: .default))
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
        }
        .padding()
        .background(ZStack{
            Image("NeslisLaunchScreen")
                .blur(radius: (1 - 0.6) * 20)
                .scaledToFill()
            Color.black.opacity(0.7)
        })
        .onAppear() {
            DispatchQueue.main.async {
                IAPManager.shared.getProducts()
            }
        }
        
        
        
    }
}
