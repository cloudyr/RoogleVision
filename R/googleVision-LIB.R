### types!
# TYPE_UNSPECIFIED	Unspecified feature type.
# FACE_DETECTION	Run face detection.
# LANDMARK_DETECTION	Run landmark detection.
# LOGO_DETECTION	Run logo detection.
# LABEL_DETECTION	Run label detection.
# TEXT_DETECTION	Run OCR.
# SAFE_SEARCH_DETECTION	Run various computer vision models to compute image safe-search properties.
# IMAGE_PROPERTIES	Compute a set of properties about the image (such as the images dominant colors).



############################################################
#' @title helper function to load required packages
#' @description Thanks to http://stackoverflow.com/questions/4090169/elegant-way-to-check-for-missing-packages-and-install-them
#'
checkAndLoadPackages <- function(){
  list.of.packages <- c("googleAuthR", "RCurl", "stringr", "httr")
  new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
  if(length(new.packages)) install.packages(new.packages)
  
  require(stringr)
  require(httr)
  require(RCurl)
  require(googleAuthR)

}

############################################################
#' @title helper function base_encode code the image file
#' @description 
#'
#' @param provide path/url to image

#' @return get the image back as encoded file
#' 
imageToText <- function(imagePath){
  checkAndLoadPackages()
  
  if(str_count(imagePath, "http")>0){### its a url!
    content = getBinaryURL(imagePath)
    txt <- base64Encode(content, "txt")
  }
  else{
    txt <- base64Encode(readBin(imagePath, "raw", file.info(imagePath)[1, "size"]), "txt") 
  }
  return(txt)
}

############################################################
#' @title helper function code to extract the response data.frame
#' @description 
#'
#' @param provide the API rest response, and the feature request

#' @return get the data frame back
#' 
extractResponse <- function(pp, feature){
  if(feature == "LABEL_DETECTION"){
    return(pp$content$responses$labelAnnotations[[1]])
  }
  if(feature == "FACE_DETECTION"){
    return(pp$content$responses$faceAnnotations[[1]])
  }
  if(feature == "LOGO_DETECTION"){
    return(pp$content$responses$logoAnnotations[[1]])
  }
  if(feature == "TEXT_DETECTION"){
    return(pp$content$responses$textAnnotations[[1]])
  }
  if(feature == "LANDMARK_DETECTION"){
    return(pp$content$responses$landmarkAnnotations[[1]])
  }
}


################## Main function: Calling the API ##################
#' @title Calling Google's Cloud Vision API
#' @description input an image, provide the feature type and maxNumber of responses
#'
#' @param path or url to the image
#' @param feature: one out of: FACE_DETECTION, LANDMARK_DETECTION, LOGO_DETECTION, LABEL_DETECTION, TEXT_DETECTION
#' @export
#' @return data frame with results
#' @examples getGoogleVisionResponse(imagePath="brandlogos.png", feature="LOGO_DETECTION")
#' 
getGoogleVisionResponse <- function(imagePath, feature="LABEL_DETECTION", numResults=5){
  
  txt <- imageToText(imagePath)
  ### create Request, following the API Docs.
  if(is.na(numResults)){
    body= paste0('{  "requests": [    {   "image": { "content": "',txt,'" }, "features": [  { "type": "',feature,'", "maxResults": ',numResults,'} ],  }    ],}')
    
  }
  else{
    body= paste0('{  "requests": [    {   "image": { "content": "',txt,'" }, "features": [  { "type": "',feature,'" } ],  }    ],}')
    
  }

  simpleCall <- gar_api_generator(baseURI = "https://vision.googleapis.com/v1/images:annotate", http_header="POST" )
  ## set the request!
  pp <- simpleCall(the_body = body)
  ## obtain results.
  res <- extractResponse(pp, feature)
  
  return(res)
}


