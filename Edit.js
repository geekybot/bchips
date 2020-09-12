
import React, {useState} from "react";

// reactstrap components
import {
  Button,
  Card,
  CardHeader,
  CardBody,
  FormGroup,
  Form,
  Input,
  Container,
  Row,
  Col,
  DropdownToggle,
  Dropdown,
  DropdownItem, 
  DropdownMenu,
  Label
} from "reactstrap";
// core components
import UserHeader from "components/Headers/UserHeader.js";


const DropSelectToken = (props) => {
  const [dropdownOpen, setDropdownOpen] = useState(false);

  const toggle = () => setDropdownOpen(prevState => !prevState);

  return (
    <Dropdown isOpen={dropdownOpen} toggle={toggle}>
      <DropdownToggle caret>
        Select
        </DropdownToggle>
      <DropdownMenu>
       <DropdownItem>A Token</DropdownItem>
        <DropdownItem>B Token</DropdownItem>
        <DropdownItem>C Token</DropdownItem>
      </DropdownMenu>
    </Dropdown>
  );
}


let uri = {
  "name": "NY Tokens",
  "description": "NY times tokens.",
  "localization": {
    "uri": "ipfs://QmWS1VAdMD353A6SDk9wNyvkT14kyCiZrNDYAad4w1tKqT/{locale}.json",
    "default": "en",
    "locales": ["en", "es", "fr"]
  }
}

class Profile extends React.Component {
  render() {
    return (
      <>
        <UserHeader />
        {/* Page content */}
        <Container className="mt--7" fluid>
          <Row>
            <Col className="order-xl-1" xl="8">
              <Card className="bg-secondary shadow">
                <CardHeader className="bg-white border-0">
                  <Row className="align-items-center">
                    <Col xs="8">
                      <h3 className="mb-0">Edit Token Information</h3>
                    </Col>
                   
                  </Row>
                </CardHeader>
                <CardBody>
                  <Form>
                   
                  <FormGroup>
                            <label
                              className="form-control-label"
                              htmlFor="input-first-name"
                            >
                              Token : 
                            </label>
                            <br></br>
                          <DropSelectToken></DropSelectToken>
                          </FormGroup>
                      
                    <div className="pl-lg-4">
                      <FormGroup>
                      
                           <label
                              className="form-control-label"
                              htmlFor="input-username"
                            >
                              Asset Information
                            </label>
                        <Input
                          className="form-control-alternative"
                          placeholder="A few words about you ..."
                          rows="4"
                          defaultValue={JSON.stringify(uri,null,'\t')}
                          type="textarea"
                        />
                        <br></br>
                        <Button
                        color="primary"
                        href="#pablo"
                        onClick={e => e.preventDefault()}
                        size="sm"
                      >
                        Edit
                      </Button>
                      </FormGroup>
                    </div>
                  </Form>
                  
                </CardBody>
              </Card>
            </Col>
          </Row>
        </Container>
      </>
    );
  }
}

export default Profile;
