package com.dasi.domain.auth.service;

import com.dasi.domain.ai.service.armory.IArmoryStrategy;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;


import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Slf4j
@Service
public class AuthStrategyFactory {

    public final Map<String, IAuthStrategy> type2StrategyMap = new ConcurrentHashMap<>();

    public AuthStrategyFactory(Map<String, IAuthStrategy> authStrategyMap) {

        for (Map.Entry<String, IAuthStrategy> entry : authStrategyMap.entrySet()) {
            IAuthStrategy authStrategy = entry.getValue();
            type2StrategyMap.put(entry.getKey(), authStrategy);
        }
    }

    public IAuthStrategy getAuthStrategy(String type) {
        return type2StrategyMap.get(type);
    }
}
