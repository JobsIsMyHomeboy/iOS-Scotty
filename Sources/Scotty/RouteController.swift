//
//  RouteController.swift
//  Routes
//
//  Copyright © 2017 Bottle Rocket Studios. All rights reserved.
//

import Foundation

/// The RouteController object handles the execution of routes as entry points into your application.
/// The route controller is generic over its root, meaning that it will only accept routes that begin in the same root type as it was created with.
open class RouteController<Root>: NSObject {
    
    // MARK: Properties
	fileprivate let root: Root
    fileprivate(set) var isPreparedForRouting = false
	fileprivate(set) var storedRoute: (() -> Void)?
    
    // MARK: Initializers
    public init(root: Root, ready: Bool = true) {
        self.root = root
        super.init()
        
        setRouteHandling(enabled: ready)
    }
}

// MARK: Route Processing
public extension RouteController {
	
	/// Attempts to open (and execute) any object that conforms to the Routable protocol, passing in the providing routing options during execution. If routing reaches its intended destination, returns true. Otherwise returns false.
	///
	/// - Parameters:
	///   - routable: The object to be executed.
	///   - options: Any routing options that should be taken into account when routing.
	/// - Returns: Returns true if routing reaches its intended destination, otherwise returns false.
    @discardableResult
    func open(_ route: Route<Root>?, options: [AnyHashable: Any]? = nil) -> Bool {
        guard let route = route else { return false }
        guard isPreparedForRouting || !route.isSuspendable else { storedRoute = stored(route: route, options: options); return false }
        return route.route(fromRoot: root, options: options)
    }
}

// MARK: Routing Availability
public extension RouteController {
	
	/// The StoredRoutePolicy determines the outcome of any routes the RouteController has stored when it resumes handling routes.
	///
	/// - execute: The stored route will be executed, and then cleared.
	/// - clear: The stored route will be cleared. It will not be executed.
	/// - none: The stored route will not be cleared or executed.
	enum StoredRoutePolicy {
		case execute
		case clear
		case none
		
		fileprivate func executePolicy(with routeController: RouteController<Root>) {
			switch self {
			case .execute:
				routeController.executeStoredRoute()
			case .clear:
				routeController.clearStoredRoute()
			default: return
			}
		}
	}
	
	/// Instructs the controller to resume route handling.
	///
	/// - Parameter storedRoutePolicy: Determines how any stored (as yet unexecuted) routes should be handled at resume time.
	func resumeHandlingRoutes(with storedRoutePolicy: StoredRoutePolicy = .execute) {
        isPreparedForRouting = true
		storedRoutePolicy.executePolicy(with: self)
    }
	
    /// Instructs the controller to suspend route handling. Note that even while route handling is suspended, any routes where isSuspendable = false will still be executed.
    func suspendHandlingRoutes() {
        isPreparedForRouting = false
    }
	
    /// Modify the route controller's ability to handle routes.
    ///
    /// - Parameter enabled: Passing in true will allow the controller to resume handling routes.
    /// False will suspend route handling. Note that even while route handling is suspended, any routes where isSuspendable = false will still be executed.
    func setRouteHandling(enabled: Bool) {
        enabled ? resumeHandlingRoutes() : suspendHandlingRoutes()
	}
}

// MARK: Stored (Delayed) Links
fileprivate extension RouteController {
	
	func executeStoredRoute() {
		storedRoute?()
		clearStoredRoute()
	}
	
	func clearStoredRoute() {
		storedRoute = nil
	}
}

// MARK: Route Storage
fileprivate extension RouteController {
    
    func stored(route: Route<Root>, options: [AnyHashable: Any]?) -> () -> Void {
        return { [weak self] in
            self?.open(route, options: options)
        }
    }
}
