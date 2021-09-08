import Foundation
#if !COCOAPODS
    import ApolloUtils
#endif

public final class GraphQLFragmentWatcher<Fragment: GraphQLFragment>: Cancellable, ApolloStoreSubscriber {
    public typealias FragmentResultHandler = (Result<GraphQLResult<Fragment>, Error>) -> Void

    weak var client: ApolloClientProtocol?
    let resultHandler: FragmentResultHandler

    private let callbackQueue: DispatchQueue
  
    private let cacheKey: CacheKey

    private let contextIdentifier = UUID()

    private class WeakCancellableContainer {
        weak var cancellable: Cancellable?
        fileprivate init(_ cancellable: Cancellable?) {
            self.cancellable = cancellable
        }
    }

    private var dependentKeys: Atomic<Set<CacheKey>?> = Atomic(nil)

    public init(
        client: ApolloClientProtocol,
        forType ofFragment: Fragment.Type,
        cacheKey: CacheKey,
        callbackQueue: DispatchQueue = .main,
        resultHandler: @escaping FragmentResultHandler
    ) {
        self.client = client
        self.cacheKey = cacheKey
        self.resultHandler = resultHandler
        self.callbackQueue = callbackQueue

        client.store.subscribe(self)
    }

    /// Fetch the fragment, fragments are always fetched from cache only.
    func fetch() {
        client?.store.withinReadTransaction { [weak self] transaction in
            guard let `self` = self else {
              return
            }
            let mapper = GraphQLSelectionSetMapper<Fragment>()
            let dependencyTracker = GraphQLDependencyTracker()

            let (data, dependentKeys) = try transaction.execute(
                selections: Fragment.selections,
                onObjectWithKey: self.cacheKey,
                variables: [:],
                accumulator: zip(mapper, dependencyTracker)
            )
          
          self.dependentKeys.mutate {
              $0 = dependentKeys
          }
          self.resultHandler(.success(GraphQLResult(data: data, extensions: nil, errors: nil, source: .cache, dependentKeys: dependentKeys)))
        }
    }

    public func cancel() {
        client?.store.unsubscribe(self)
    }

    func store(
        _: ApolloStore,
        didChangeKeys changedKeys: Set<CacheKey>,
        contextIdentifier: UUID?
    ) {
        if let incomingIdentifier = contextIdentifier,
           incomingIdentifier == self.contextIdentifier
        {
            return
        }

        guard let dependentKeys = self.dependentKeys.value else {
            return
        }

        if !dependentKeys.isDisjoint(with: changedKeys) {
            fetch()
        }
    }
}
