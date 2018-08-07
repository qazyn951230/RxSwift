//
//  CompactMap.swift
//  RxSwift
//

extension ObservableType {

    /**
     Projects each element of an observable sequence into a new form.

     - parameter transform: A transform function to apply to each source element.
     - returns: An observable sequence whose elements are the result of invoking the transform function on each element of source.

     */
    public func compactMap<R>(_ transform: @escaping (E) throws -> R?)
        -> Observable<R> {
        return CompactMap(source: asObservable(), transform: transform)
    }
}

final fileprivate class CompactMapSink<SourceType, O : ObserverType> : Sink<O>, ObserverType {
    typealias Transform = (SourceType) throws -> ResultType?

    typealias ResultType = O.E
    typealias Element = SourceType

    private let _transform: Transform
    
    init(transform: @escaping Transform, observer: O, cancel: Cancelable) {
        _transform = transform
        super.init(observer: observer, cancel: cancel)
    }

    func on(_ event: Event<SourceType>) {
        switch event {
        case .next(let element):
            do {
                if let compactMappedElement = try _transform(element) {
                    forwardOn(.next(compactMappedElement))
                }
            } catch let e {
                forwardOn(.error(e))
                dispose()
            }
        case .error(let error):
            forwardOn(.error(error))
            dispose()
        case .completed:
            forwardOn(.completed)
            dispose()
        }
    }
}

final fileprivate class CompactMap<SourceType, ResultType>: Producer<ResultType> {
    typealias Transform = (SourceType) throws -> ResultType?

    private let _source: Observable<SourceType>

    private let _transform: Transform

    init(source: Observable<SourceType>, transform: @escaping Transform) {
        _source = source
        _transform = transform
    }
    
    override func run<O: ObserverType>(_ observer: O, cancel: Cancelable)
        -> (sink: Disposable, subscription: Disposable) where O.E == ResultType {
        let sink = CompactMapSink(transform: _transform, observer: observer, cancel: cancel)
        let subscription = _source.subscribe(sink)
        return (sink: sink, subscription: subscription)
    }
}
