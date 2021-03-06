{-# LANGUAGE OverloadedStrings #-}
import Network.HTTP.Enumerator
import System.Environment
import qualified Data.ByteString.Lazy as L
import Blaze.ByteString.Builder
import Blaze.ByteString.Builder.Char.Utf8 (fromString)
import Data.Monoid (mconcat)
import qualified Data.ByteString.Char8 as S8

main = do
    args <- getArgs
    let (url, pass, file) =
            case args of
                [x, y] -> (x, "", y)
                [x, y, z] -> (x, y, z)
                _ -> error "Usage: yackage-upload <url> [password] <file>"
    req <- parseUrl url
    body <- mkBody pass file
    let req' = req
            { method = "POST"
            , requestHeaders =
                [ ("Content-Type", "multipart/form-data; boundary=" `S8.append` bound)
                , ("Content-Length", S8.pack $ show $ L.length body)
                ]
            , requestBody = body
            }
    res <- httpLbs req'
    L.putStrLn $ responseBody res

bound = "YACKAGEUPLOAD"

mkBody pass file = do
    file' <- L.readFile file
    let boundary = fromByteString bound
    return $ toLazyByteString $ mconcat
        [ fromByteString "--"
        , boundary
        , fromByteString "\r\nContent-Disposition: form-data; name=\"password\"\r\nContent-Type: text/plain\r\n\r\n"
        , fromString pass
        , fromByteString "\r\n--"
        , boundary
        , fromByteString "\r\nContent-Disposition: form-data; name=\"file\"; filename=\""
        , fromString file
        , fromByteString "\"\r\nContent-Type: application/x-tar\r\n\r\n"
        , fromLazyByteString file'
        , fromByteString "\r\n--"
        , boundary
        , fromByteString "--\r\n"
        ]
