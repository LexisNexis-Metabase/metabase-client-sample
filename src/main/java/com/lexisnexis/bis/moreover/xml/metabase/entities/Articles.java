package com.lexisnexis.bis.moreover.xml.metabase.entities;

import java.util.List;

import javax.xml.bind.annotation.XmlElement;

public class Articles {

    private List<Article> articles;

    @XmlElement(name = "article")
    public List<Article> getArticles() {
        return articles;
    }

    public void setArticles(List<Article> articles) {
        this.articles = articles;
    }
    
}
