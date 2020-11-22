//
//  PurchaseView.swift
//  Neslis
//
//  Created by Sergey Volkov on 23.08.2020.
//  Copyright © 2020 Sergei Volkov. All rights reserved.
//

import SwiftUI


struct PurchaseView: View {
    
    @EnvironmentObject var loading: Loadspinner
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        
        VStack(alignment: .center, spacing: 14) {
            Text("Choose a plan for Pro version")
                .font(Font.system(size: 22, weight: .bold, design: .default))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
            
            VStack {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Data backup")
                        .foregroundColor(.white)
                        .lineLimit(nil)
                        .multilineTextAlignment(.leading)
                }
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Sharing lists")
                        .foregroundColor(.white)
                        .lineLimit(nil)
                        .multilineTextAlignment(.leading)
                }
            }
            //.padding(20)
            
            
            Button(action: {
                IAPManager.shared.purshase(product: IAPManager.shared.products[0])
            }) {
                Text("\(IAPManager.shared.products[0].localizedTitle) \(IAPManager.shared.priceOfProduct(product: IAPManager.shared.products[0])) / month")
                    .lineLimit(nil)
                    .multilineTextAlignment(.center)
                    .font(.subheadline)
                
            }
            .modifier(SettingButtonModifire(disable: false))
            .cornerRadius(12)
            .frame(width: 200, height: 80)
            
            
            Button(action: {
                IAPManager.shared.purshase(product: IAPManager.shared.products[1])
            }) {
                VStack{
                    Text("\(IAPManager.shared.products[1].localizedTitle) \(IAPManager.shared.priceOfProduct(product: IAPManager.shared.products[1])) / year")
                        .lineLimit(nil)
                        .multilineTextAlignment(.center)
                        .font(.subheadline)
                    
                    Text("Your save \(Int(round(100 - Double(truncating: IAPManager.shared.products[1].price) / (Double(truncating: IAPManager.shared.products[0].price) * 12) * 100)))%")
                        //.padding(.top)
                    .font(Font.system(size: 22, weight: .bold, design: .default))
                        
                }
            }
            .modifier(PurchaseButtonModifire())
            
            Text("""
                Recurring billing. Cancel any time.
                If you choose to purchase a subscription, payment will be charged to your iTunes account and your account will be charged fo renewal 24 yours prior to the end of the current period unless auto-renew is turned off. Auto-renewal is managed by user and may be turned off at any time by going to your settings in the iTunes Store after purchase. Any unused portion of a free trial period will be forfeited when the user purchases a subscription.
                """)
                .font(.system(size: 12, weight: .thin, design: .default))
                .foregroundColor(.white)
                .lineLimit(nil)
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
