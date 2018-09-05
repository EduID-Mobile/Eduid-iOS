# EduID iOS
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

The main iOS native mobile app for EduID-Mobile project. This app will act as an authorization provider and provides authorization service(EduID) to the iPhone user.

EduID iOS performs identically like the [EduID Android](https://github.com/EduID-Mobile/EduID-Android). The only different thing from these two apps are the way they communicate through the other app. This topic is explained more clearly in the specification of the [NAIL API](https://github.com/EduID-Mobile/Architecture-and-Requirements/blob/master/40-nail-api.md).

For its function this app depends on the [JWTSwift Framework](https://github.com/EduID-Mobile/JWTswift). Developer could include this framework easily at the first installation with the help of carthage.

## Main Function

As shortly mentioned above this app does no other thing than to provide a Single Sign On(SSO) services, that currently missing for the swiss universities. Since the universities do NOT use SSO services from common Identity Provider such as Facebook/ Google. This missing service is currently being develop for the whole project of EduID, which could be summarised as a centralized system for the swiss universities. This app itself is a part from the EduID project, and act as a mobile Identity provider and communicate with other apps that require Authentication & Authorization from EduID.
With this universities could just focus on developing their mobile app and not wasting time for the security of the credentials exchange on sign in process. This gives a chance for the app developer to develop an app that not strongly attached for a university so an app that works for university registered on EduID system (ex. Moodle Mobile App).

## Diagram

![Flow Diagram](https://github.com/EduID-Mobile/Eduid-iOS/blob/master/FlowDiagram%20EduID%20iOS.png)
To learn more about how the whole system interract with each other and the specification behind it, click [here](https://github.com/EduID-Mobile/Architecture-and-Requirements)

## How it works

This app acts like a middle man for the whole conversation between a mobile app, Identity Provider and Service Provider.
So it communicates with multiple endpoints to make this works. There are two types of communication that EduID iOS does, they are inside and outside communication.

Based on the diagram above, flow number 1,2,4 and 7 are outside communications.
And flow number 3 and 8 are the inside communication.

### Outside
Outside communication is no other than communication to endpoints outside the device, through REST API. The communication partner for this is no other than Identity Provider (ex. EduID server) and Service Provider (ex. Univeristy service).
This is where the credentials would be exchanged through the network, therefore this communication needs to be secure through TLS and also using a secure protocol OIDC(OpenID Connect).
OIDC itself is an extension of OAuth2 protocol, what it exactly differs from OAuth2 is the extra identity layer for the data exchange. With this extra layer the app and the server could identify and verify the incoming data if they are coming from a valid partner with a valid signature as well. This prevents man in the middle attack.

### Inside
Inside communication is the way the EduID iOS communicate with the other mobile app, that uses EduID iOS service to authenticate and authorize its users. The communication itself happens through extension and NAIL API. The source code for implementing NAIL API could be found [here](https://github.com/EduID-Mobile/NAIL-iOS).
