//
//  Authorization.swift
//  Krampus
//
//  Created by Christian Braun on 08.01.20.
//

import Foundation
import Santa

public protocol Authorization: RequestAuthorization {
    var jwt: JWT? { get }

    var isLoggedIn: Bool { get }
    
    func login(withUsername username: String, password: String, completion:  @escaping (Result<Void, Error>) -> Void)

    func login(withAuthCode code: String, completion:  @escaping (Result<Void, Error>) -> Void)

    func logout(completion: @escaping (Result<Void, Error>) -> Void)
}
