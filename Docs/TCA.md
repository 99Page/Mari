# TCA

프로젝트 내에서 TCA 적용 방식에 대해서 정리한 문서 

## Event Propagation 

서로 다른 ViewController 계층 간에 이벤트를 처리는 '최단거리'를 기준으로 합니다. 

```
Root  
└── Tab  
    ├── AccountStack  
    │   ├── Path  
    │   │   ├── MyPost  
    │   │   └── PostDetail  
    │   └── UserAccount  
    └── MapStack  
        ├── Map  
        └── Path  
            └── PostDetail  
```
PostDetail에서 포스트 삭제 후, MyPost에 이를 반영하기 위해서는 가장 가까운 AccountStack에서 처리합니다. 

AccountStack-Path-PostDetail에서 포스트 삭제 후, Map에 반영하는 것은 Tab에서 처리합니다. 