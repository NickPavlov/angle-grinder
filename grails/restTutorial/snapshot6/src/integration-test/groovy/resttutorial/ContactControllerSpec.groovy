package resttutorial

import grails.plugins.rest.client.RestBuilder
import grails.plugins.rest.client.RestResponse
import grails.test.mixin.integration.Integration
import org.grails.web.json.JSONElement
import spock.lang.Shared
import spock.lang.Specification

@Integration
class ContactControllerSpec extends Specification {

	@Shared
	RestBuilder rest = new RestBuilder()

	def getBaseUrl() { "http://localhost:${serverPort}/api" }

	String token
	def setup() {
		RestResponse response = rest.post(baseUrl + "/login") {
			json([
					"username": "user",
					"password": "pass"
			])
		}
		token = "Bearer " +response.json.access_token
	}

	def cleanup() {
	}


	void "check GET list request without params "() {
		when:
		RestResponse response = rest.get("${baseUrl}/contact"){
			headers["Authorization"] = token
		}

		then:
		response.status == 200
		response.json != null
		JSONElement json = response.json.rows
		//by default max value is 10 rows
		json.size() == 10
		json[0].firstName == "Marie"
		json[0].lastName == "Scott"
		json[0].email == "mscott0@ameblo.jp"
	}

	void "check GET list request with max parameter"() {
		when: "list endpoint with max param"
		RestResponse response = rest.get("${baseUrl}/contact?max=20"){
			headers["Authorization"] = token
		}

		then:
		response.status == 200
		response.json != null
		JSONElement json = response.json.rows
		json.size() == 20
		json[0].firstName == "Marie"
		json[0].lastName == "Scott"
		json[0].email == "mscott0@ameblo.jp"
	}

	void "check GET by id"() {
		when:
		RestResponse response = rest.get("${baseUrl}/contact/1"){
			headers["Authorization"] = token
		}

		then:
		response.status == 200
		response.json != null
		JSONElement json = response.json
		json.firstName == "Marie"
		json.lastName == "Scott"
		json.email == "mscott0@ameblo.jp"

	}

	void "check POST request"() {
		when:
		RestResponse response = rest.post("${baseUrl}/contact") {
			headers["Authorization"] = token
			json([
					firstName: "Test contact",
					"email"  : "foo@bar.com",
					inactive : true
			])
		}

		then:
		response.status == 201
		response.json != null
		JSONElement json = response.json
		json.firstName == "Test contact"
		json.lastName == null
		json.email == "foo@bar.com"
		json.inactive == null
	}

	void "check POST request with name field"() {
		when:
		RestResponse response = rest.post("${baseUrl}/contact") {
			headers["Authorization"] = token
			json([
					name   : "Joe Cool",
					"email": "foo@bar.com"
			])
		}

		then:
		response.status == 201
		response.json != null
		JSONElement json = response.json
		json.firstName == "Joe"
		json.lastName == "Cool"
	}


	void "check PUT request"() {
		when:
		RestResponse response = rest.put("${baseUrl}/contact/101") {
			headers["Authorization"] = token
			json([
					firstName: "new Test contact",
					"email"  : "newfoo@bar.com",
					lastName : "Doe"
			])
		}

		then:
		response.status == 200
		response.json != null
		JSONElement json = response.json
		json.id == 101
		json.firstName == "new Test contact"
		json.lastName == "Doe"
		json.email == "newfoo@bar.com"
	}

	void "check DELETE request"() {
		when:
		RestResponse response = rest.delete("${baseUrl}/contact/1"){
			headers["Authorization"] = token
		}

		then:
		response.status == 200
	}

	void "check inactivate endpoint"() {
		when:
		RestResponse response = rest.delete("${baseUrl}/contact/2/active"){
			headers["Authorization"] = token
		}

		then:
		response.status == 200
		response.json != null
		JSONElement json = response.json
		json.inactive == true
	}

	void "check GET Address by contact"() {
		when:
		RestResponse response = rest.get("${baseUrl}/contact/3/address"){
			headers["Authorization"] = token
		}

		then:
		response.status == 200
		response.json != null
		println(response.json)
		JSONElement json = response.json.rows
		json.size() == 1
		json[0].city == "Houston"
		json[0].country == "US"
		json[0].postalCode == "77255"
		json[0].street == "5105 Valley Edge Place"
	}
}
