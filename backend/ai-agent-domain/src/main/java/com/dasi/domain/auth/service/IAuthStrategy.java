package com.dasi.domain.auth.service;


public interface IAuthStrategy {

    void login();

    void register();

    String getType();
}
