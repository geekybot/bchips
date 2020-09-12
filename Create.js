
import React from "react";

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
  Col
} from "reactstrap";
// core components
import UserHeader from "components/Headers/UserHeader.js";

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
  constructor(props) {
    super(props);
    this.state = {
      name: "NY Times Token",
      symbol : "NYT"
    }
    this.onChangeName = this.onChangeName.bind(this) 
    this.onChangeSymbol = this.onChangeSymbol.bind(this) 
  }
  onChangeName(value) {
    this.setState({name : value})
  }
  onChangeSymbol(value) {
    this.setState({symbol : value})
  }
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
                      <h3 className="mb-0">Create a new asset</h3>
                    </Col>
                   
                  </Row>
                </CardHeader>
                <CardBody>
                  <Form>
                   
                    <h6 className="heading-small text-muted mb-4">Token Information</h6>
                    <div className="pl-lg-4">
                      <FormGroup>
                      
                        {/* <Input
                          className="form-control-alternative"
                          placeholder="A few words about you ..."
                          rows="4"
                          defaultValue={JSON.stringify(uri,null,'\t')}
                          type="textarea"
                        /> */}
                         <label
                              className="form-control-label"
                              htmlFor="input-username"
                            >
                              Name
                            </label>
                        <Input
                          className="form-control-alternative"
                          placeholder=""
                          defaultValue="NY Times"
                          type="text"
                          value={this.state.name}
                          onChange={(e)=>this.onChangeName(e.target.value)}
                        />
                        <br></br>
                        <label
                              className="form-control-label"
                              htmlFor="input-username"
                            >
                              Symbol
                            </label>
                        <Input
                        className="form-control-alternative"
                        placeholder=""
                        defaultValue="NYT"
                        type="text"
                        value={this.state.symbol}
                        onChange={(e)=>this.onChangeSymbol(e.target.value)}
                      />
                        <br></br>
                        <Button
                        color="primary"
                        href="#pablo"
                        onClick={e => e.preventDefault()}
                        size="sm"
                      >
                        Create
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
