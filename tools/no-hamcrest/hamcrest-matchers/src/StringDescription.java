package com.hsbc.contact;

public class StringDescription implements Description {
    StringBuilder stringBuilder = new StringBuilder();

    @Override
    public void appendText(String text) {
        stringBuilder.append(text);
    }

    @Override
    public String toString() {
        return stringBuilder.toString();
    }
}
