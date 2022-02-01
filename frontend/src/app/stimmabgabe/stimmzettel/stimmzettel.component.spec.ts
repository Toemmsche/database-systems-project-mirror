import { ComponentFixture, TestBed } from '@angular/core/testing';

import { StimmzettelComponent } from './stimmzettel.component';

describe('StimmzettelComponent', () => {
  let component: StimmzettelComponent;
  let fixture: ComponentFixture<StimmzettelComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ StimmzettelComponent ]
    })
    .compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(StimmzettelComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
