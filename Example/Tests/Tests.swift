import XCTest
import Santa
import Krampus

class Tests: XCTestCase {
    let webservice = ImplWebservice()
    lazy var authorization = {
        return Krampus.keycloakAuthorization(
            baseUrl: "https://keycloak-url.de",
            clientId: "client",
            realm: "realm",
            redirectUrl: "",
            keychain: CredentialsKeychain(credentialsServiceName: "KeychainTestKrampusLogin"),
            webservice: webservice)
    }()

    override func setUp() {
        super.setUp()
        webservice.authorization = authorization
    }
    

    func testLoginWithUsernamePassword() {
        let expec = expectation(description: "Login with username password")
        authorization.login(withUsername: "username", password: "password") { result in
            switch result {
            case .success:
                expec.fulfill()
            case .failure(let error):
                print(error)
                XCTFail("Login failed")
            }
        }
        waitForExpectations(timeout: 2, handler: nil)
    }

    func testAuthorizationWorking() {
        let resource = DataResource<String>(url: "requesturl", method: .get, body: nil) { data -> String? in
            return String(data: data, encoding: .utf8)
        }

        let expec = expectation(description: "Authenticated network call should work")
        webservice.load(resource: resource) { response, error in
            if let error = error {
                print(error)
                XCTFail("Unable to authenticate")
                return
            }
            guard let response = response else {
                XCTFail("Response was empty")
                return
            }
            print(response)
            XCTAssertTrue(response.first == "{", "Response must be json formatted")
            expec.fulfill()
        }
        waitForExpectations(timeout: 2, handler: nil)
    }
}
