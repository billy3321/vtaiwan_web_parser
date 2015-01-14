## 簡介

這是一個解析網路文章的網站，初步支援：Facebook、PTT。

## 使用說明

貼上網址送出後，網站會把該文內容標題、內容抓下，並把下方的留言（或推文）放到資料庫中。
可輸入留言（推文）者id，系統會過濾、留下他們的推文。

資料庫目前使用SQLite3。

## 架站說明

#### 設定

```
cp config/config.yml.default config/config.yml
cp config/database.yml.default config/database.yml
```

`config.yml` 內請貼上 Facebook app id及 app secret 。
`database.yml` 應該不用多做設定。

#### 以測試模式開站

```
bundle install
rake db:create
rake db:migrate
```

最後執行

```
rails server
```

即可以測試模式運行，請再瀏覽器中打開 `http://localhost:3000/`

#### 測試

請於目錄中執行：

```
rake db:create db:migrate RAILS_ENV=test
rspec spec/
```

不過，目前測試不涵蓋Facebook，請手動登入測試。