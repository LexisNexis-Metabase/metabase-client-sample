package com.lexisnexis.bis.moreover.xml.metabase.entities;

import javax.xml.bind.annotation.XmlRootElement;

@XmlRootElement(name="response")
public class XMLResponse {

    private String status;

    private String messageCode;

    private String userMessage;

    private String developerMessage;

    private Articles articles;

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public String getMessageCode() {
        return messageCode;
    }

    public void setMessageCode(String messageCode) {
        this.messageCode = messageCode;
    }

    public String getUserMessage() {
        return userMessage;
    }

    public void setUserMessage(String userMessage) {
        this.userMessage = userMessage;
    }

    public String getDeveloperMessage() {
        return developerMessage;
    }

    public void setDeveloperMessage(String developerMessage) {
        this.developerMessage = developerMessage;
    }

    public Articles getArticles() {
        return articles;
    }

    public void setArticles(Articles articles) {
        this.articles = articles;
    }
    
}
