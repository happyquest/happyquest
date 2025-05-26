#!/bin/bash

# テスト環境の起動
docker-compose -f docker-compose.test.yml up -d

# テストの実行
docker-compose -f docker-compose.test.yml exec test-server pytest \
    --cov=. \
    --cov-report=term-missing \
    -v \
    tests/

# テスト環境の停止
docker-compose -f docker-compose.test.yml down 