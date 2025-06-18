# README

Service 폴더에 대해서 정리한 문서

## Overview

![ServiceModule](ServiceModule)

초기의 모듈화 계획은, API 호출하는 계층(Service)는 분리하는 것이었습니다. ComposableArchitecture는 Core에서 의존하고 있기때문에 Service는 Core를 의존해야합니다. 

Core, Service 모듈은 각각 staticLibrary로 구성해야 하는데, 이렇게 할 경우 `tuist generate`를 했을 때 정상적으로 의존 관게가 생기지 않습니다. 

static framework 간 의존은 최종 바이너리에 포함될 필요가 있을 때만 링크되고, 자동 링크가 제공되지 않습니다. 이를 해결하려면 Service나 Core 둘 중 하나는 dynamic framework가 되어야합니다. 

하지만 dynamic framework는 런타임에 리소스를 차지하고, 배포되는 앱의 용량이 커지기 때문에 지양했습니다. 

결론적으로 Service 모듈을 분리하지 않았고, `Rim` 내부에 폴더로 분리했습니다. 이는 위에서 말한 문제를 해결하기 위함이기도 하며, 앱이 충분히 커졌을 때 모듈화로 컴파일 타임을 얼마나 줄일 수 있는지 확인해보기 위함이기도 합니다. 
