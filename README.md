## 簡介

這是一個解析網路文章的網站，初步支援：Facebook、PTT。

## 使用說明

貼上網址送出後，網站會把該文內容標題、內容抓下，並把下方的留言（或推文）放到資料庫中。
可輸入留言（推文）者id，系統會過濾、留下他們的推文。

資料庫目前使用SQLite3。

## 架站說明

bundle install
rails s
