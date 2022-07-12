//
//  FetchManager.swift
//  SwiftChat
//
//  Created by Kevin Sandoval on 7/11/22.
//

import Foundation

func executePipeline() {

    let headers = [
      "Accept": "application/json",
      "Content-Type": "application/json",
      "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhY2MiOiI2MmE3NTRiN2QzZGQ3NjA0YzJjMWE5MDUiLCJleHAiOjE2NTkwMjYxMzksImlzcyI6ImpvdXJuZXkiLCJwcnAiOiJzeXN0ZW0ifQ.8HsokKX0emauIzVbhCNL4GsWJW1k5pzJfWBt3vDTMDI"
    ]
    let parameters = [
      "delivery": [
        "method": "sms",
        "phoneNumber": "+18885554321"
      ],
      "customer": ["uniqueId": "example@journeyid.com"],
      "callbackUrls": ["https://us-central1-journey-zoom.cloudfunctions.net"],
      "language": "en-US",
      "pipelineKey": "6570ce40-97f1-4cf7-aedb-27d04783490c"
    ] as [String : Any]

    let postData = try? JSONSerialization.data(withJSONObject: parameters, options: [])

    let request = NSMutableURLRequest(url: NSURL(string: "https://app.journeyid.io/api/system/executions")! as URL,
                                            cachePolicy: .useProtocolCachePolicy,
                                        timeoutInterval: 10.0)
    request.httpMethod = "POST"
    request.allHTTPHeaderFields = headers
    request.httpBody = postData! as Data

    let session = URLSession.shared
    let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
      if (error != nil) {
          print(error ?? "error")
      } else {
        let httpResponse = response as? HTTPURLResponse
          print(httpResponse ?? "response")
      }
    })

    dataTask.resume()
}
