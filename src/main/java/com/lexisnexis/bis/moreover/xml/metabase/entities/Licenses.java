package com.lexisnexis.bis.moreover.xml.metabase.entities;

import java.util.List;

import javax.xml.bind.annotation.XmlElement;

public class Licenses {
    
    private List<License> licenses;

    @XmlElement(name="license")
    public List<License> getLicenses() {
        return licenses;
    }

    public void setLicenses(List<License> licenses) {
        this.licenses = licenses;
    }

}
