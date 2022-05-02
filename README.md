# 개요

BEP20 기반의 DOMEX 토큰을 생성하는 소스코드

# 개발 환경

- Solidity v0.8.7
- Tuffle v5.5.7
- Node v14.18.0

# 파일 구성

- `./contracts/`: 스마트 컨트랙트 소스 코드를 모아 둔 디렉토리

- `./deployed-files/` : 배포 후 ABI 파일과 owner address 를 파일로 export 한 다음 모아둔 디렉토리

- `./migrations/` : 배포 소스 코드를 모아둔 디렉토리

- `./test/` : 테스트 소스 코드를 모아둔 디렉토리

- `./secret/` : private key 등 외부에 공개되면 안되는 파일들을 모아둔 디렉토리

- `./truffle-config.js` : 트러플 설정 파일

# 컴파일 방법

```
    truffle compile
```

# 배포 방법

```
    truffle migration bsc_mainnet
```
