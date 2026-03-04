package com.dasi.domain.auth.service.strategy;

import com.dasi.domain.auth.service.IAuthStrategy;
import org.springframework.stereotype.Service;

@Service
public class AdminAuthStrategy implements IAuthStrategy {

    @Override
    public void login() {
        System.out.println("Testing: Strategy Factory for Admin login");
    }

    @Override
    public void register() {
        System.out.println("Testing: Strategy Factory for Admin register");
    }

    @Override
    public String getType() {
        return "Admin";
    }
}
