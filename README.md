# LoopMate

友人とルームを作成し、日々の継続行動や達成状況を共有できる iOS アプリです。  
習慣化やモチベーション維持を、チーム単位で支援することを目的としています。

---

## 主な機能

- ルーム作成・参加
- フレンド機能
- ミッション（タスク）管理
- カレンダーによる進捗可視化
- 達成率の表示

---

## 技術スタック

- SwiftUI
- Firebase Authentication（匿名認証）
- Cloud Firestore
- Swift Concurrency（async/await 一部使用）

---

## 設計方針

本アプリでは、UI とデータ処理の責務を分離することを意識して設計しています。

- View（SwiftUI）
  - 画面描画とユーザー操作の処理を担当

- Service 層
  - Firebase との通信やデータ取得・更新処理を集約

例として、ルーム関連の処理は `RoomService` に集約し、  
View から直接 Firestore を操作しない構造としています。

また、プロフィール存在確認処理を `RootView` から `UserService` に移動することで、  
データアクセスロジックの分離を行っています。

---

## 工夫した点

### 1. Firestore のデータ整合性

ルーム作成時は `batch` を使用し、

- ルーム情報
- メンバー情報

を同時に作成することで、データの不整合を防いでいます。

また、ルーム参加処理では `transaction` を使用し、

- 重複参加の防止
- memberCount の整合性維持

を実現しています。

---

### 2. Navigation設計

`NavigationStack` + enum によるルーティングを採用し、  
型安全かつ拡張しやすい画面遷移を実現しています。

---

### 3. 匿名認証フロー

アプリ起動時に匿名ログインを行い、  
プロフィール未登録ユーザーのみ登録画面を表示することで、

- 初回体験のハードルを下げる
- 不要な入力を避ける

設計にしています。

---

## 課題・改善点

- ViewModel 層が未導入であり、一部ロジックが View に残っている
- 非同期処理が async/await と callback の混在状態
- Service クラスの責務が肥大化している（特に RoomService）

今後は MVVM 構造への移行や、非同期処理の統一を進める予定です。

---

## セットアップ方法

本リポジトリには `GoogleService-Info.plist` は含まれていません。

アプリを起動するには以下の手順が必要です：

1. Firebase プロジェクトを作成
2. iOS アプリを登録
3. `GoogleService-Info.plist` をダウンロード
4. `LoopMate/` ディレクトリに配置

---

## 今後の展望

- ViewModel の導入による設計改善
- 非同期処理の async/await への統一
- テストコードの追加
- UI/UX の改善

---

## スクリーンショット

<p align="center">
  <img src="https://github.com/user-attachments/assets/8bf7d34f-9355-47d4-92f3-4b6c472c914d" width="260">
  <img src="https://github.com/user-attachments/assets/db5c13b6-e52f-4152-8c07-8fc3588b3fbd" width="260">
</p>

<p align="center">
  <img src="https://github.com/user-attachments/assets/cfee7ff6-579e-4032-be5f-28994720ef9f" width="260">
  <img src="https://github.com/user-attachments/assets/ddf3844b-1900-4704-958e-618a8721c4dc" width="260">
</p>
