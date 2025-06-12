FROM swift:latest AS build

WORKDIR /build
COPY ./Package.* ./
COPY . .

RUN swift package resolve

# Build SpeziFoundation & Tests
RUN swift build  --build-tests -v



# Testing with Swift Testing
RUN swift test --skip-build --disable-xctest

# Testing with XCTest: May happen that the XCTests are hanging in the dockerfile
RUN swift test --skip-build --disable-swift-testing

