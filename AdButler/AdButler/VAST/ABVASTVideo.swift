import Foundation
import WebKit

public class ABVASTVideo : UIViewController, WKUIDelegate {
    
    private var rect:CGRect?
    private var webView:WKWebView?
    private var zoneID:Int!
    private var accountID:Int!
    private var publisherID:Int!
    private var poster:String!
    private var sources:[Source]?
    private var delegate:ABVASTDelegate?
    private var videoPlayer:ABVideoPlayer!
    
    
    private let baseurl = "https://servedbyadbutler.com"
    
    struct Source {
        public var source:String!
        public var type:String!
    }
    
    public func initialize(accountID:Int, zoneID:Int, publisherID:Int, delegate:ABVASTDelegate?, poster:String? = ""){
        self.zoneID = zoneID
        self.accountID = accountID
        self.publisherID = publisherID
        self.poster = poster
        self.delegate = delegate
    }
    
    public func addSource(source:String, type:String){
        if(sources == nil){
            sources = Array()
        }
        sources!.append(Source(source:source, type:type))
    }
    
    private func getVideoJSMarkup() -> String {
        var str = """
        <html>
        <head>
        <meta name="viewport" content="initial-scale=1.0" />
        <link href="http://vjs.zencdn.net/4.12/video-js.css" rel="stylesheet">
        <script src="http://vjs.zencdn.net/4.12/video.js"></script>
        <link href="\(baseurl)/videojs-vast-vpaid/bin/videojs.vast.vpaid.min.css" rel="stylesheet">
        <script src="\(baseurl)/videojs-vast-vpaid/bin/videojs_4.vast.vpaid.min.js"></script>
        </head>
        <body style="margin:0px; background-color:black">
        <video id="av_video" class="video-js vjs-default-skin" playsinline="true" autoplay="true"
        """
        str += "controls preload=\"auto\" width=\"100%\" height=\"100%\" "
        if(self.poster != ""){
            str += "poster=\"\(self.poster!)\" "
        }
        str += "data-setup='{ "
        str += "\"plugins\": { "
        str += "\"vastClient\": { "
        str += "\"adTagUrl\": \"\(baseurl)/vasttemp.spark?setID=\(self.zoneID!)&ID=\(self.accountID!)&pid=\(self.publisherID!)\", "
        str += "\"adCancelTimeout\": 5000, "
        str += "\"adsEnabled\": true "
        str += "} "
        str += "} "
        str += "}'> "
        if(sources != nil){
            for s in sources! {
                str += "<source src=\"\(s.source!)\" type='\(s.type!)'/>"
            }
        }else{
            str += "<source src=\"\(baseurl)/assets/blank.mp4\" type='video/mp4'/>"
        }
        str += """
        <p class="vjs-no-js">
        To view this video please enable JavaScript, and consider upgrading to a web browser that
        <a href="http://videojs.com/html5-video-support/" target="_blank">supports HTML5 video</a>
        </p>
        </video>
        </body>
        </html>
        """
        return str
    }
    
    public func play(){
        videoPlayer = ABVideoPlayer()
        videoPlayer.addCloseButtonToVideo = false
        let body = self.getVideoJSMarkup()
        let previousRootController = UIApplication.shared.delegate?.window??.rootViewController
        ABMRAIDUtilities.setRootController(videoPlayer)
        videoPlayer.playHTMLVideo(body, delegate:self.delegate, onClose: {() in
            ABMRAIDUtilities.setRootController(previousRootController!)
            self.videoPlayer.dismiss(animated:false, completion:nil)
        })
    }
}
