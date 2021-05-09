//
//  PreviewViewController.swift
//  GeoJSONPreview
//
//  Created by griffin-stewie on 2021/05/08.
//  
//

import Cocoa
import Quartz
import MapKit

class PreviewViewController: NSViewController, QLPreviewingController {

    @IBOutlet weak var imageView: NSImageView!

    let imageSize = CGSize(width: 600, height: 450)
    
    override var nibName: NSNib.Name? {
        return NSNib.Name("PreviewViewController")
    }

    override func loadView() {
        super.loadView()

        preferredContentSize = NSSize(width: imageSize.width, height: imageSize.height)
    }


    /*
     * Implement this method and set QLSupportsSearchableItems to YES in the Info.plist of the extension if you support CoreSpotlight.
     *
     func preparePreviewOfSearchableItem(identifier: String, queryString: String?, completionHandler handler: @escaping (Error?) -> Void) {
     // Perform any setup necessary in order to prepare the view.

     // Call the completion handler so Quick Look knows that the preview is fully loaded.
     // Quick Look will display a loading spinner while the completion handler is not called.
     handler(nil)
     }
     */
    
    func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
        
        // Add the supported content types to the QLSupportedContentTypes array in the Info.plist of the extension.
        
        // Perform any setup necessary in order to prepare the view.
        
        // Call the completion handler so Quick Look knows that the preview is fully loaded.
        // Quick Look will display a loading spinner while the completion handler is not called.

        do {
            let data = try Data(contentsOf: url)
            guard let geojson = try MKGeoJSONDecoder().decode(data) as? [MKGeoJSONFeature] else {
                throw PreviewError.custom("デコード失敗")
            }

            guard let feature = geojson.first, let coordinate = feature.geometry.first?.coordinate else {
                throw PreviewError.custom("失敗")
            }


            let span = MKCoordinateSpan(latitudeDelta: 0.003, longitudeDelta: 0.003)
            let options = MKMapSnapshotter.Options()
            options.showsBuildings = true
            options.pointOfInterestFilter = .includingAll
            options.size = imageSize
            options.region = MKCoordinateRegion(center: coordinate, span: span)
            options.mapType = .standard
            let snapshotter = MKMapSnapshotter(options: options)
            snapshotter.start(with: DispatchQueue.global(qos: .userInteractive)) { snapshot, error in
                guard error == nil else {
                    handler(error)
                    return
                }

                guard let snapshot = snapshot else {
                    handler(PreviewError.custom("SnapShot インスタンスが nil"))
                    return
                }

                let rect = NSRect(x: 0, y: 0, width: options.size.width, height: options.size.height)
                guard let snapShotImageRep = snapshot.image.bestRepresentation(for: rect, context: nil, hints: nil) else {
                    handler(PreviewError.custom("representation is nil!"))
                    return
                }

                let compositImage = NSImage(size: options.size, flipped: false) { _ in
                    snapShotImageRep.draw(at: .zero)

                    let pinImage = NSImage(named: "Oval")!

                    var point = snapshot.point(for: coordinate)

                    guard rect.contains(point) else {
                        return false
                    }

                    point.x -= pinImage.size.width / 2
                    point.y -= pinImage.size.height / 2

                    pinImage.draw(at: point, from: rect, operation: .sourceOver, fraction: 1.0)
                    return true
                }

                DispatchQueue.main.async {
                    self.imageView.image = compositImage
                    handler(nil)
                }
            }
        } catch {
            handler(error)
        }
    }
}

enum PreviewError: Error {
    case custom(String)
}
