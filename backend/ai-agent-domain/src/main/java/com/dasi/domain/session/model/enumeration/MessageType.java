package com.dasi.domain.session.model.enumeration;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@AllArgsConstructor
@NoArgsConstructor
public enum MessageType {
    CHAT("chat", "Chat"),
    WORK_SSE("work-sse", "Work SSE"),
    WORK_ANSWER("work-answer", "Work Answer");

    private String type;

    private String name;

}
