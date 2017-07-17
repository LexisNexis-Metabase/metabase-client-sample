package com.lexisnexis.bis.moreover.xml.metabase.entities;

import javax.xml.bind.annotation.XmlElement;

public class License {

    private String name;

    @XmlElement
    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }    
    
}
